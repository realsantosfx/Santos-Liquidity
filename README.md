# Santos-Liquidity

## Overview
The Santos Liquidity Indicator is a custom indicator designed for MetaTrader 4 (MT4) that identifies Order Blocks (OB) and significant liquidity levels in the market. This indicator aids traders in visualizing potential areas of market reversals and liquidity pools by drawing lines and rectangles on the chart, highlighting bullish and bearish order blocks, and marking liquidity voids.

### Features
- Order Block Identification: Automatically detects and highlights bullish and bearish order blocks based on user-defined criteria.
- Engulfing Highlights: Highlights engulfing patterns with customizable colors, aiding in the visualization of strong reversal signals.
- Liquidity Levels: Marks significant liquidity levels where buy or sell-side liquidity is likely to be present.
- High and Low Price Lines: Draws horizontal lines at recent high and low prices for better market structure visualization.
- Alerts: Provides configurable alerts (sound, popup, push, email) for significant market events.
- Customizable: Offers extensive customization options for colors, line styles, and other visual elements to suit individual trading styles.

### Input Parameters
- TimeFrame: Select the timeframe for the indicator (default is the current timeframe).
- FractalPeriod: Set the period for fractal calculation.
- OBLineDraw: Enable or disable drawing lines on OB candles.
- OBLineEngulfing: Enable or disable drawing lines only on engulfing OB candles.
- OBLineEngulfingType: Choose between body or wick for engulfing type.
- OBLineType: Choose between body or wick for OB line type.
- Alerts: Enable or disable various alert types (sound, popup, push, email).
- OBLineLength: Set the length of the OB lines in bars.
- OBLineColorBull: Set the color for bullish OB lines.
- OBLineColorBear: Set the color for bearish OB lines.
- OBLineWidth: Set the width of the OB lines.
- OBLineStyle: Set the style of the OB lines.
- EngulfingHighlight: Enable or disable highlighting of engulfing patterns.
- EngulfingHighlightColorBull: Set the color for bullish engulfing highlights.
- EngulfingHighlightColorBear: Set the color for bearish engulfing highlights.
- High and Low Line Configuration: Configure the appearance of high and low price lines, including color and font size.

### Installation
1. Download the Santos Liquidity V2.mq4 file.
2.Open MetaTrader 4.
3. Go to File -> Open Data Folder.
4. Navigate to MQL4 -> Indicators.
5. Copy the downloaded Santos Liquidity V2.mq4 file into the Indicators folder.
6. Restart MetaTrader 4.
7. In the Navigator window, find Santos_OB under Custom Indicators.
8. Attach the indicator onto a chart and configure the settings as desired.

### Usage
- The indicator will automatically identify and draw order blocks and liquidity levels on the chart.
- Customize the appearance and behavior of the indicator through the input parameters.
- Use the drawn lines and rectangles to identify potential reversal points and areas of significant market liquidity.

### Notes
- Ensure that the FractalPeriod is set to a reasonable value based on your trading timeframe to avoid excessive calculation load.
- The indicator provides various customization options to fit different trading strategies and visual preferences.

