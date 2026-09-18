Add-Type -AssemblyName System.Drawing

function New-RoundedRectanglePath {
    param(
        [System.Drawing.RectangleF]$Bounds,
        [float]$Radius
    )

    $diameter = $Radius * 2
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc($Bounds.X, $Bounds.Y, $diameter, $diameter, 180, 90)
    $path.AddArc($Bounds.Right - $diameter, $Bounds.Y, $diameter, $diameter, 270, 90)
    $path.AddArc($Bounds.Right - $diameter, $Bounds.Bottom - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($Bounds.X, $Bounds.Bottom - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function Save-FinovoIcon {
    param(
        [int]$Size,
        [string]$OutputPath
    )

    $bitmap = [System.Drawing.Bitmap]::new($Size, $Size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)

    [float]$padding = $Size * 0.08
    [float]$radius = $Size * 0.22
    [float]$backgroundSize = $Size - (2 * $padding)
    $backgroundBounds = [System.Drawing.RectangleF]::new($padding, $padding, $backgroundSize, $backgroundSize)
    $backgroundPath = New-RoundedRectanglePath -Bounds $backgroundBounds -Radius $radius

    $topColor = [System.Drawing.Color]::FromArgb(255, 18, 55, 42)
    $bottomColor = [System.Drawing.Color]::FromArgb(255, 31, 110, 98)
    $accentColor = [System.Drawing.Color]::FromArgb(255, 232, 164, 76)
    $whiteColor = [System.Drawing.Color]::FromArgb(255, 245, 247, 245)

    $gradientBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.PointF]::new($backgroundBounds.Left, $backgroundBounds.Top),
        [System.Drawing.PointF]::new($backgroundBounds.Right, $backgroundBounds.Bottom),
        $topColor,
        $bottomColor
    )
    $graphics.FillPath($gradientBrush, $backgroundPath)

    $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(70, $accentColor))
    $graphics.FillEllipse(
        $glowBrush,
        $Size * 0.56,
        $Size * 0.14,
        $Size * 0.24,
        $Size * 0.24
    )

    $barBrush = New-Object System.Drawing.SolidBrush($accentColor)
    $barWidth = $Size * 0.09
    $barGap = $Size * 0.04
    $barStartX = $Size * 0.26
    $barBaseY = $Size * 0.70
    $barHeights = @(
        [float]($Size * 0.16),
        [float]($Size * 0.25),
        [float]($Size * 0.37)
    )

    for ($index = 0; $index -lt $barHeights.Count; $index++) {
        $barHeight = [float]$barHeights[$index]
        $barX = $barStartX + ($index * ($barWidth + $barGap))
        $barRect = [System.Drawing.RectangleF]::new(
            [float]$barX,
            [float]($barBaseY - $barHeight),
            [float]$barWidth,
            [float]$barHeight
        )
        $graphics.FillRectangle($barBrush, $barRect)
    }

    $linePen = New-Object System.Drawing.Pen($whiteColor, ($Size * 0.045))
    $linePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $linePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $linePen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

    $points = [System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new([float]($Size * 0.24), [float]($Size * 0.63)),
        [System.Drawing.PointF]::new([float]($Size * 0.39), [float]($Size * 0.50)),
        [System.Drawing.PointF]::new([float]($Size * 0.50), [float]($Size * 0.57)),
        [System.Drawing.PointF]::new([float]($Size * 0.69), [float]($Size * 0.34))
    )
    $graphics.DrawLines($linePen, $points)
    $graphics.DrawLine($linePen, $Size * 0.69, $Size * 0.34, $Size * 0.64, $Size * 0.35)
    $graphics.DrawLine($linePen, $Size * 0.69, $Size * 0.34, $Size * 0.68, $Size * 0.39)

    $outlinePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(36, 255, 255, 255), ($Size * 0.008))
    $graphics.DrawPath($outlinePen, $backgroundPath)

    $directory = Split-Path -Parent $OutputPath
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }

    $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $outlinePen.Dispose()
    $linePen.Dispose()
    $barBrush.Dispose()
    $glowBrush.Dispose()
    $gradientBrush.Dispose()
    $backgroundPath.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

$outputs = @{
    "assets/branding/finovo_icon_source.png" = 1024
    "android/app/src/main/res/mipmap-mdpi/ic_launcher.png" = 48
    "android/app/src/main/res/mipmap-hdpi/ic_launcher.png" = 72
    "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png" = 96
    "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png" = 144
    "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" = 192
}

foreach ($output in $outputs.GetEnumerator()) {
    Save-FinovoIcon -Size $output.Value -OutputPath $output.Key
}
