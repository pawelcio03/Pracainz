const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");

initializeApp();

const portfolioBackfillToken = defineSecret("PORTFOLIO_BACKFILL_TOKEN");
const supportedAssetTypes = new Set(["crypto"]);
const quoteCurrencies = ["USDT", "USDC", "USD", "EUR", "PLN", "GBP", "BTC", "ETH"];

exports.fetchInvestmentHistory = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (request) => {
    return fetchInvestmentHistoryPayload(request.data);
  },
);

exports.fetchInvestmentHistoryHttp = onRequest(
  {
    region: "europe-west1",
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (request, response) => {
    response.set("Access-Control-Allow-Origin", "*");
    response.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    response.set("Access-Control-Allow-Headers", "Content-Type");

    if (request.method === "OPTIONS") {
      response.status(204).send("");
      return;
    }

    if (request.method !== "POST") {
      response.status(405).json({
        error: {
          status: "METHOD_NOT_ALLOWED",
          message: "Uzyj metody POST.",
        },
      });
      return;
    }

    try {
      const result = await fetchInvestmentHistoryPayload(request.body);
      response.status(200).json(result);
    } catch (error) {
      if (error instanceof HttpsError) {
        response.status(statusCodeForHttpsError(error.code)).json({
          error: {
            status: error.code.toUpperCase().replaceAll("-", "_"),
            message: error.message,
            details: error.details ?? null,
          },
        });
        return;
      }

      response.status(503).json({
        error: {
          status: "UNAVAILABLE",
          message: "Nie udalo sie pobrac danych rynkowych z backendu.",
        },
      });
    }
  },
);

exports.refreshInvestmentQuotesDaily = onSchedule(
  {
    region: "europe-west1",
    schedule: "every day 03:15",
    timeZone: "Europe/Warsaw",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async () => {
    const firestore = getFirestore();
    const snapshot = await firestore.collectionGroup("investments").get();
    if (snapshot.empty) {
      return { updatedGroups: 0, failedGroups: 0, skippedGroups: 0 };
    }

    const groupedInvestments = new Map();
    for (const document of snapshot.docs) {
      const data = document.data() ?? {};
      const assetType = normalizeStoredAssetType(data.assetType);
      const symbol = normalizeStoredSymbol(data.symbol);
      if (!assetType || !symbol || !supportedAssetTypes.has(assetType)) {
        continue;
      }

      const key = `${assetType}|${symbol}`;
      const investmentsForKey = groupedInvestments.get(key) ?? [];
      investmentsForKey.push({
        document,
        assetType,
        symbol,
      });
      groupedInvestments.set(key, investmentsForKey);
    }

    let updatedGroups = 0;
    let failedGroups = 0;
    let skippedGroups = 0;

    for (const investmentsForKey of groupedInvestments.values()) {
      const [{ assetType, symbol }] = investmentsForKey;

      try {
        const prices = await fetchCryptoHistory({ symbol, maxPoints: 30 });

        if (!prices.length) {
          skippedGroups++;
          continue;
        }

        const latestPrice = prices[0];
        const now = new Date();

        for (const investment of investmentsForKey) {
          const parentRef = investment.document.ref;
          const batch = firestore.batch();
          batch.update(parentRef, {
            currentPrice: latestPrice.closePrice,
            lastPriceDate: Timestamp.fromDate(new Date(latestPrice.priceDate)),
            lastPriceUpdateAt: Timestamp.fromDate(now),
            updatedAt: FieldValue.serverTimestamp(),
          });

          for (const point of prices) {
            const pointDate = new Date(point.priceDate);
            batch.set(
              parentRef.collection("priceHistory").doc(pricePointId(pointDate)),
              {
                investmentId: parentRef.id,
                closePrice: point.closePrice,
                priceDate: Timestamp.fromDate(pointDate),
                recordedAt: Timestamp.fromDate(now),
                updatedAt: FieldValue.serverTimestamp(),
              },
              { merge: true },
            );
          }

          await batch.commit();
        }

        updatedGroups++;
      } catch (error) {
        failedGroups++;
        console.error("refreshInvestmentQuotesDaily failed", {
          assetType,
          symbol,
          message: error instanceof Error ? error.message : String(error),
        });
      }
    }

    return {
      updatedGroups,
      failedGroups,
      skippedGroups,
    };
  },
);

exports.saveDailyPortfolioSnapshots = onSchedule(
  {
    region: "europe-west1",
    schedule: "every day 08:00",
    timeZone: "Europe/Warsaw",
    timeoutSeconds: 540,
    memory: "256MiB",
  },
  async () => {
    const firestore = getFirestore();
    const investmentsSnapshot = await firestore.collectionGroup("investments").get();
    if (investmentsSnapshot.empty) {
      return { savedUsers: 0, skippedUsers: 0 };
    }

    const totalsByUser = new Map();
    for (const document of investmentsSnapshot.docs) {
      const userRef = document.ref.parent.parent;
      if (!userRef) {
        continue;
      }

      const data = document.data() ?? {};
      const units = Number(data.units);
      const currentPrice = Number(data.currentPrice);
      if (!Number.isFinite(units) || !Number.isFinite(currentPrice)) {
        continue;
      }

      const userId = userRef.id;
      const currentValue = units * currentPrice;
      totalsByUser.set(userId, (totalsByUser.get(userId) ?? 0) + currentValue);
    }

    if (!totalsByUser.size) {
      return { savedUsers: 0, skippedUsers: 0 };
    }

    const recordedAt = new Date();
    const snapshotId = portfolioSnapshotId(recordedAt, "Europe/Warsaw");
    let batch = firestore.batch();
    let batchOperations = 0;
    let savedUsers = 0;
    let skippedUsers = 0;

    for (const [userId, value] of totalsByUser.entries()) {
      if (!Number.isFinite(value)) {
        skippedUsers++;
        continue;
      }

      const snapshotRef = firestore
        .collection("users")
        .doc(userId)
        .collection("dailyPortfolioSnapshots")
        .doc(snapshotId);
      batch.set(
        snapshotRef,
        {
          recordedAt: Timestamp.fromDate(recordedAt),
          value: Number(value.toFixed(2)),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      batchOperations++;
      savedUsers++;

      if (batchOperations >= 450) {
        await batch.commit();
        batch = firestore.batch();
        batchOperations = 0;
      }
    }

    if (batchOperations > 0) {
      await batch.commit();
    }

    return {
      savedUsers,
      skippedUsers,
      snapshotId,
    };
  },
);

exports.backfillDailyPortfolioSnapshotsHttp = onRequest(
  {
    invoker: "public",
    region: "europe-west1",
    timeoutSeconds: 540,
    memory: "1GiB",
    secrets: [portfolioBackfillToken],
  },
  async (request, response) => {
    response.set("Access-Control-Allow-Origin", "*");
    response.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    response.set("Access-Control-Allow-Headers", "Authorization, Content-Type");

    if (request.method === "OPTIONS") {
      response.status(204).send("");
      return;
    }

    if (request.method !== "POST") {
      response.status(405).json({
        error: {
          status: "METHOD_NOT_ALLOWED",
          message: "Uzyj metody POST.",
        },
      });
      return;
    }

    const expectedToken = portfolioBackfillToken.value();
    if (!expectedToken) {
      response.status(500).json({
        error: {
          status: "FAILED_PRECONDITION",
          message: "Token backfillu nie jest jeszcze skonfigurowany.",
        },
      });
      return;
    }

    const providedToken = extractBearerToken(request.get("Authorization")) ??
      normalizeOptionalString(request.body?.token);
    if (providedToken !== expectedToken) {
      response.status(403).json({
        error: {
          status: "PERMISSION_DENIED",
          message: "Brak dostepu do backfillu snapshotow portfela.",
        },
      });
      return;
    }

    try {
      const hydratePriceHistory = request.body?.hydratePriceHistory == null
        ? true
        : normalizeBoolean(request.body?.hydratePriceHistory);

      const result = await backfillDailyPortfolioSnapshots({
        firestore: getFirestore(),
        hydratePriceHistory,
        overwrite: normalizeBoolean(request.body?.overwrite),
        timeZone: "Europe/Warsaw",
        userId: normalizeOptionalString(request.body?.userId),
      });
      response.status(200).json(result);
    } catch (error) {
      if (error instanceof HttpsError) {
        response.status(statusCodeForHttpsError(error.code)).json({
          error: {
            status: error.code.toUpperCase().replaceAll("-", "_"),
            message: error.message,
            details: error.details ?? null,
          },
        });
        return;
      }

      response.status(500).json({
        error: {
          status: "INTERNAL",
          message: "Nie udalo sie wykonac backfillu snapshotow portfela.",
        },
      });
    }
  },
);

function normalizeAssetType(value) {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", "Brakuje typu aktywa.");
  }

  const normalized = value.trim().toLowerCase();
  if (!normalized) {
    throw new HttpsError("invalid-argument", "Brakuje typu aktywa.");
  }

  return normalized;
}

async function fetchInvestmentHistoryPayload(payload) {
  const rawData = payload?.data ?? payload;
  const assetType = normalizeAssetType(rawData?.assetType);
  if (!supportedAssetTypes.has(assetType)) {
    throw new HttpsError(
      "invalid-argument",
      "Ten typ aktywa nie obsluguje automatycznego feedu kursowego.",
    );
  }

  const symbol = normalizeSymbol(rawData?.symbol);
  const maxPoints = normalizeMaxPoints(rawData?.maxPoints);

  try {
    const prices = await fetchCryptoHistory({ symbol, maxPoints });

    return {
      fetchedAt: new Date().toISOString(),
      prices,
    };
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError(
      "unavailable",
      "Nie udalo sie pobrac danych rynkowych z backendu.",
    );
  }
}

function statusCodeForHttpsError(code) {
  switch (code) {
    case "invalid-argument":
      return 400;
    case "unauthenticated":
      return 401;
    case "permission-denied":
      return 403;
    case "not-found":
      return 404;
    case "resource-exhausted":
      return 429;
    case "failed-precondition":
      return 412;
    case "unavailable":
      return 503;
    default:
      return 500;
  }
}

function normalizeSymbol(value) {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", "Brakuje tickera.");
  }

  const normalized = value.trim().toUpperCase();
  if (!normalized) {
    throw new HttpsError("invalid-argument", "Brakuje tickera.");
  }

  if (normalized.length > 24) {
    throw new HttpsError("invalid-argument", "Ticker jest za dlugi.");
  }

  return normalized;
}

function normalizeMaxPoints(value) {
  const fallback = 30;
  if (value == null) {
    return fallback;
  }

  const numeric = Number(value);
  if (!Number.isFinite(numeric)) {
    return fallback;
  }

  return Math.max(5, Math.min(90, Math.trunc(numeric)));
}

function normalizeBoolean(value) {
  if (typeof value === "boolean") {
    return value;
  }

  if (typeof value === "number") {
    return value !== 0;
  }

  if (typeof value === "string") {
    const normalized = value.trim().toLowerCase();
    return normalized === "true" || normalized === "1" || normalized === "yes";
  }

  return false;
}

function normalizeOptionalString(value) {
  if (typeof value !== "string") {
    return null;
  }

  const normalized = value.trim();
  return normalized || null;
}

function normalizeStoredAssetType(value) {
  if (typeof value !== "string") {
    return null;
  }

  const normalized = value.trim().toLowerCase();
  return normalized || null;
}

function normalizeStoredSymbol(value) {
  if (typeof value !== "string") {
    return null;
  }

  const normalized = value.trim().toUpperCase();
  return normalized || null;
}

async function fetchCryptoHistory({ symbol, maxPoints }) {
  const pair = resolveCryptoPair(symbol);
  const url = new URL("https://api.binance.com/api/v3/klines");
  url.searchParams.set("symbol", pair.binanceSymbol);
  url.searchParams.set("interval", "1d");
  url.searchParams.set("limit", String(maxPoints));

  try {
    const payload = await fetchJson(url);
    if (!Array.isArray(payload)) {
      throw new HttpsError(
        "unavailable",
        "Provider krypto nie zwrocil poprawnej historii cen.",
      );
    }

    const prices = payload
      .map((row) => {
        if (!Array.isArray(row)) {
          return null;
        }

        const openTime = Number(row[0]);
        const closePrice = Number(row[4]);
        if (!Number.isFinite(openTime) || !Number.isFinite(closePrice)) {
          return null;
        }

        return {
          priceDate: new Date(openTime).toISOString(),
          closePrice,
        };
      })
      .filter(Boolean)
      .sort((left, right) => right.priceDate.localeCompare(left.priceDate))
      .slice(0, maxPoints);

    if (prices.length > 0) {
      return prices;
    }
  } catch (error) {
    if (!(error instanceof HttpsError)) {
      throw error;
    }
  }

  return [await fetchCryptoExchangeRate({ pair })];
}

async function fetchCryptoExchangeRate({ pair }) {
  const url = new URL("https://api.binance.com/api/v3/ticker/price");
  url.searchParams.set("symbol", pair.binanceSymbol);

  const payload = await fetchJson(url);
  const closePrice = Number(payload?.price);
  if (!Number.isFinite(closePrice)) {
    throw new HttpsError(
      "not-found",
      `Nie znaleziono aktualnego kursu dla ${pair.binanceSymbol}.`,
    );
  }

  return {
    priceDate: toIsoDate(new Date().toISOString().slice(0, 10)),
    closePrice,
  };
}

function resolveCryptoPair(symbol) {
  const compactSymbol = symbol.replace(/[^A-Z0-9]/g, "");
  if (!compactSymbol) {
    throw new HttpsError("invalid-argument", "Brakuje tickera krypto.");
  }

  if (compactSymbol.length <= 5) {
    const marketSymbol = "USDT";
    return {
      baseSymbol: compactSymbol,
      marketSymbol,
      binanceSymbol: `${compactSymbol}${marketSymbol}`,
    };
  }

  for (const quoteCurrency of quoteCurrencies) {
    if (
      compactSymbol.endsWith(quoteCurrency) &&
      compactSymbol.length > quoteCurrency.length
    ) {
      const baseSymbol = compactSymbol.slice(0, -quoteCurrency.length);
      const marketSymbol = normalizeCryptoMarket(quoteCurrency);
      return {
        baseSymbol,
        marketSymbol,
        binanceSymbol: `${baseSymbol}${marketSymbol}`,
      };
    }
  }

  const marketSymbol = "USDT";
  return {
    baseSymbol: compactSymbol,
    marketSymbol,
    binanceSymbol: `${compactSymbol}${marketSymbol}`,
  };
}

function normalizeCryptoMarket(symbol) {
  if (symbol === "USD") {
    return "USDT";
  }

  return symbol;
}

function toIsoDate(value) {
  return new Date(`${value}T00:00:00.000Z`).toISOString();
}

function pricePointId(date) {
  const month = `${date.getUTCMonth() + 1}`.padStart(2, "0");
  const day = `${date.getUTCDate()}`.padStart(2, "0");
  return `${date.getUTCFullYear()}-${month}-${day}`;
}

function portfolioSnapshotId(date, timeZone) {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(date);
}

function extractBearerToken(authorizationHeader) {
  if (typeof authorizationHeader !== "string") {
    return null;
  }

  const [scheme, token] = authorizationHeader.trim().split(/\s+/, 2);
  if (!scheme || !token || scheme.toLowerCase() !== "bearer") {
    return null;
  }

  return token.trim() || null;
}

async function backfillDailyPortfolioSnapshots({
  firestore,
  hydratePriceHistory,
  overwrite,
  timeZone,
  userId,
}) {
  const userInvestments = userId
    ? new Map([
      [
        userId,
        (await firestore.collection("users").doc(userId).collection("investments").get()).docs,
      ],
    ])
    : await loadInvestmentsByUser(firestore);

  let processedUsers = 0;
  let skippedUsers = 0;
  let failedUsers = 0;
  let savedSnapshots = 0;
  let skippedSnapshots = 0;
  const userResults = [];

  for (const [resolvedUserId, investmentDocs] of userInvestments.entries()) {
    if (!investmentDocs.length) {
      skippedUsers++;
      continue;
    }

    try {
      const result = await backfillUserPortfolioSnapshots({
        firestore,
        hydratePriceHistory,
        investmentDocs,
        overwrite,
        timeZone,
        userId: resolvedUserId,
      });
      processedUsers++;
      savedSnapshots += result.savedSnapshots;
      skippedSnapshots += result.skippedSnapshots;
      userResults.push(result);
    } catch (error) {
      failedUsers++;
      console.error("backfillDailyPortfolioSnapshots failed", {
        userId: resolvedUserId,
        message: error instanceof Error ? error.message : String(error),
      });
    }
  }

  return {
    processedUsers,
    skippedUsers,
    failedUsers,
    savedSnapshots,
    skippedSnapshots,
    users: userResults,
  };
}

async function loadInvestmentsByUser(firestore) {
  const snapshot = await firestore.collectionGroup("investments").get();
  const userInvestments = new Map();

  for (const document of snapshot.docs) {
    const userRef = document.ref.parent.parent;
    if (!userRef) {
      continue;
    }

    const investmentsForUser = userInvestments.get(userRef.id) ?? [];
    investmentsForUser.push(document);
    userInvestments.set(userRef.id, investmentsForUser);
  }

  return userInvestments;
}

async function backfillUserPortfolioSnapshots({
  firestore,
  hydratePriceHistory,
  investmentDocs,
  overwrite,
  timeZone,
  userId,
}) {
  const userRef = firestore.collection("users").doc(userId);
  const existingSnapshotsPromise = userRef.collection("dailyPortfolioSnapshots").get();
  const priceHistoryPromises = investmentDocs.map((document) =>
    document.ref.collection("priceHistory").orderBy("priceDate").get()
  );

  const [existingSnapshots, ...initialPriceHistorySnapshots] = await Promise.all([
    existingSnapshotsPromise,
    ...priceHistoryPromises,
  ]);
  let priceHistorySnapshots = initialPriceHistorySnapshots;

  let hydratedInvestments = 0;
  if (hydratePriceHistory) {
    const hydration = await hydrateInvestmentPriceHistory({
      investmentDocs,
      priceHistorySnapshots,
    });
    priceHistorySnapshots = hydration.priceHistorySnapshots;
    hydratedInvestments = hydration.hydratedInvestments;
  }

  let earliestPriceDateKey = null;
  let latestPriceDateKey = null;
  const investmentStates = investmentDocs.map((document, index) => {
    const data = document.data() ?? {};
    const currentUnits = Number(data.units);
    const priceHistorySnapshot = priceHistorySnapshots[index];
    const pricePoints = [];

    for (const priceDocument of priceHistorySnapshot.docs) {
      const priceData = priceDocument.data() ?? {};
      const closePrice = Number(priceData.closePrice);
      const priceDate = priceData.priceDate instanceof Timestamp
        ? priceData.priceDate.toDate()
        : null;
      if (!Number.isFinite(closePrice) || !priceDate) {
        continue;
      }

      const dateKey = portfolioSnapshotId(priceDate, timeZone);
      earliestPriceDateKey = minDateKey(earliestPriceDateKey, dateKey);
      latestPriceDateKey = maxDateKey(latestPriceDateKey, dateKey);
      pricePoints.push({ dateKey, closePrice });
    }

    pricePoints.sort((left, right) => left.dateKey.localeCompare(right.dateKey));

    const resolvedCurrentUnits = Number.isFinite(currentUnits) ? currentUnits : 0;

    return {
      id: document.id,
      currentUnits: resolvedCurrentUnits,
      pricePoints,
      priceIndex: 0,
      unitsHeld: resolvedCurrentUnits,
      lastKnownPrice: null,
      activated: resolvedCurrentUnits !== 0,
    };
  });

  if (!earliestPriceDateKey) {
    return {
      userId,
      savedSnapshots: 0,
      skippedSnapshots: 0,
      hydratedInvestments,
      firstDate: null,
      lastDate: null,
    };
  }

  const todayKey = portfolioSnapshotId(new Date(), timeZone);
  const lastDateKey = maxDateKey(
    todayKey,
    latestPriceDateKey,
  );
  const existingSnapshotIds = new Set(existingSnapshots.docs.map((document) => document.id));
  const dateKeys = listDateKeysBetween(earliestPriceDateKey, lastDateKey);

  let batch = firestore.batch();
  let batchOperations = 0;
  let savedSnapshots = 0;
  let skippedSnapshots = 0;

  for (const dateKey of dateKeys) {
    let hasKnownPrice = false;
    let portfolioActivated = false;
    let totalValue = 0;

    for (const state of investmentStates) {
      while (
        state.priceIndex < state.pricePoints.length &&
        state.pricePoints[state.priceIndex].dateKey.localeCompare(dateKey) <= 0
      ) {
        state.lastKnownPrice = state.pricePoints[state.priceIndex].closePrice;
        state.priceIndex++;
      }

      if (Number.isFinite(state.lastKnownPrice)) {
        hasKnownPrice = true;
        totalValue += state.unitsHeld * state.lastKnownPrice;
      }

      portfolioActivated = portfolioActivated || state.activated;
    }

    if (!hasKnownPrice || !portfolioActivated) {
      continue;
    }

    if (!overwrite && existingSnapshotIds.has(dateKey)) {
      skippedSnapshots++;
      continue;
    }

    batch.set(
      userRef.collection("dailyPortfolioSnapshots").doc(dateKey),
      {
        recordedAt: Timestamp.fromDate(snapshotDateForKey(dateKey)),
        value: Number(totalValue.toFixed(2)),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    batchOperations++;
    savedSnapshots++;

    if (batchOperations >= 400) {
      await batch.commit();
      batch = firestore.batch();
      batchOperations = 0;
    }
  }

  if (batchOperations > 0) {
    await batch.commit();
  }

  return {
    userId,
    savedSnapshots,
    skippedSnapshots,
    hydratedInvestments,
    firstDate: earliestPriceDateKey,
    lastDate: lastDateKey,
  };
}

async function hydrateInvestmentPriceHistory({
  investmentDocs,
  priceHistorySnapshots,
}) {
  const groupedInvestments = new Map();
  for (const [index, document] of investmentDocs.entries()) {
    const currentPriceHistory = priceHistorySnapshots[index];
    if (currentPriceHistory.docs.length >= 30) {
      continue;
    }

    const data = document.data() ?? {};
    const assetType = normalizeStoredAssetType(data.assetType);
    const symbol = normalizeStoredSymbol(data.symbol);
    if (!assetType || !symbol || !supportedAssetTypes.has(assetType)) {
      continue;
    }

    const key = `${assetType}|${symbol}`;
    const investmentsForKey = groupedInvestments.get(key) ?? [];
    investmentsForKey.push({ document, index });
    groupedInvestments.set(key, investmentsForKey);
  }

  let hydratedInvestments = 0;
  const refreshedIndexes = new Set();

  for (const investmentsForKey of groupedInvestments.values()) {
    const [{ document }] = investmentsForKey;
    const data = document.data() ?? {};
    const assetType = normalizeStoredAssetType(data.assetType);
    const symbol = normalizeStoredSymbol(data.symbol);
    if (!assetType || !symbol) {
      continue;
    }

    try {
      const prices = await fetchCryptoHistory({ symbol, maxPoints: 30 });
      if (!prices.length) {
        continue;
      }

      const latestPrice = prices[0];
      const now = new Date();

      for (const investment of investmentsForKey) {
        const parentRef = investment.document.ref;
        const batch = parentRef.firestore.batch();
        batch.update(parentRef, {
          currentPrice: latestPrice.closePrice,
          lastPriceDate: Timestamp.fromDate(new Date(latestPrice.priceDate)),
          lastPriceUpdateAt: Timestamp.fromDate(now),
          updatedAt: FieldValue.serverTimestamp(),
        });

        for (const point of prices) {
          const pointDate = new Date(point.priceDate);
          batch.set(
            parentRef.collection("priceHistory").doc(pricePointId(pointDate)),
            {
              investmentId: parentRef.id,
              closePrice: point.closePrice,
              priceDate: Timestamp.fromDate(pointDate),
              recordedAt: Timestamp.fromDate(now),
              updatedAt: FieldValue.serverTimestamp(),
            },
            { merge: true },
          );
        }

        await batch.commit();
        refreshedIndexes.add(investment.index);
        hydratedInvestments++;
      }
    } catch (error) {
      console.error("hydrateInvestmentPriceHistory failed", {
        assetType,
        symbol,
        message: error instanceof Error ? error.message : String(error),
      });
    }
  }

  if (!refreshedIndexes.size) {
    return {
      hydratedInvestments,
      priceHistorySnapshots,
    };
  }

  const refreshedSnapshots = [...priceHistorySnapshots];
  for (const index of refreshedIndexes) {
    refreshedSnapshots[index] = await investmentDocs[index].ref
      .collection("priceHistory")
      .orderBy("priceDate")
      .get();
  }

  return {
    hydratedInvestments,
    priceHistorySnapshots: refreshedSnapshots,
  };
}

function minDateKey(left, right) {
  if (!left) {
    return right;
  }

  if (!right) {
    return left;
  }

  return left.localeCompare(right) <= 0 ? left : right;
}

function maxDateKey(left, right, fallback) {
  if (!left) {
    return right ?? fallback ?? null;
  }

  if (!right) {
    return left;
  }

  return left.localeCompare(right) >= 0 ? left : right;
}

function listDateKeysBetween(startDateKey, endDateKey) {
  const keys = [];
  const startDate = isoDateKeyToDate(startDateKey);
  const endDate = isoDateKeyToDate(endDateKey);

  for (
    let cursor = new Date(startDate.getTime());
    cursor.getTime() <= endDate.getTime();
    cursor.setUTCDate(cursor.getUTCDate() + 1)
  ) {
    keys.push(pricePointId(cursor));
  }

  return keys;
}

function isoDateKeyToDate(value) {
  const parsed = new Date(`${value}T00:00:00.000Z`);
  if (!Number.isFinite(parsed.getTime())) {
    throw new HttpsError("invalid-argument", `Nieprawidlowa data: ${value}`);
  }

  return parsed;
}

function snapshotDateForKey(dateKey) {
  return new Date(`${dateKey}T08:00:00.000Z`);
}

async function fetchJson(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new HttpsError(
      "unavailable",
      `Zrodlo kursow zwrocilo HTTP ${response.status}.`,
    );
  }

  return response.json();
}
