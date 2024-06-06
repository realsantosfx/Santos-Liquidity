//+------------------------------------------------------------------+
//|                                          Santos Liquidity V2.mq4 |
//|                                         Copyright 2024, SantosFX |
//|                                                     realsantosfx |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, SantosFX"
#property link      "realsantosfx"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1 clrRoyalBlue
#property indicator_color2 clrRed
#property indicator_width1 2
#property indicator_width2 2

const int MAX_LINES = 25;
const string PREFIX = "JBOB_";
const string NameUpper = PREFIX + "Upper_";
const string NameLower = PREFIX + "Lower_";
const string NameEngulfing = PREFIX + "Engulfing_";

enum ENG_TYPE {
    engBody = 0, //Candle's body
    engWick = 1, //Candle's wick
};

enum enTimeFrames {
    tf_cu  = PERIOD_CURRENT, // Current time frame
    tf_m1  = PERIOD_M1,      // 1 minute
    tf_m5  = PERIOD_M5,      // 5 minutes
    tf_m15 = PERIOD_M15,     // 15 minutes
    tf_m30 = PERIOD_M30,     // 30 minutes
    tf_h1  = PERIOD_H1,      // 1 hour
    tf_h4  = PERIOD_H4,      // 4 hours
    tf_d1  = PERIOD_D1,      // Daily
    tf_w1  = PERIOD_W1,      // Weekly
    tf_mn1 = PERIOD_MN1,     // Monthly
    tf_n1  = -1,             // First higher time frame
    tf_n2  = -2,             // Second higher time frame
    tf_n3  = -3              // Third higher time frame
};

extern enTimeFrames TimeFrame = tf_cu;
input int FractalPeriod = 36;  //Fractals period
input bool OBLineDraw = true; //Line on OB Candle
input bool OBLineEngulfing = false; //Line only on engulfing OB Candle
input ENG_TYPE OBLineEngulfingType = engBody; //Engulfing type
input ENG_TYPE OBLineType = engWick; //OB Line type
input string AlertHeader = "=== Alerts ==="; //-------
input bool soundAlert = false;
input bool popupAlert = false;
input bool pushAlert = false;
input bool emailAlert = false;
input string VisualizationHeader = "=== Visualization ==="; //-------
input int OBLineLength = 15; //OB Line length, bars
input color OBLineColorBull = clrRoyalBlue; //BULL OB Line color
input color OBLineColorBear = clrRed; //BEAR OB Line color
input int OBLineWidth = 1; //OB Line width
input ENUM_LINE_STYLE OBLineStyle = STYLE_DASH; //OB Line style
input bool EngulfingHighlight = false; //Engulfing Highlight
input color EngulfingHighlightColorBull = clrRoyalBlue; //Bull engulfing Highlight color
input color EngulfingHighlightColorBear = clrRed; //Bear engulfing Highlight color

input string config_HL_Line = "===Config High Low Line ====";
input bool Show_High_Low_Line = true;
input color Color_Price_Label_High = clrSlateGray;
input color Color_Price_Lable_Low = clrSlateGray;
input int Price_Lable_Font_Size = 9;

double buffUp[], buffDown[], count[], m_level = 0.0;
datetime m_level_updated = 0;
int m_ind_upper = 0, m_ind_lower = 0;
string indicatorFileName, short_name = "";
#define _mtfCall(_buff, _ind) iCustom(NULL, TimeFrame, indicatorFileName, 0, FractalPeriod, OBLineDraw, OBLineEngulfing, OBLineEngulfingType, OBLineType, "", soundAlert, popupAlert, pushAlert, emailAlert, VisualizationHeader, OBLineLength, OBLineColorBull, OBLineColorBear, OBLineWidth, OBLineStyle, EngulfingHighlight, EngulfingHighlightColorBull, EngulfingHighlightColorBear, _buff, _ind)

int OnInit() {
    IndicatorBuffers(3);
    SetIndexStyle(0, DRAW_ARROW);
    SetIndexArrow(0, 159); //218
    SetIndexBuffer(0, buffUp);

    SetIndexStyle(1, DRAW_ARROW);
    SetIndexArrow(1, 159); //217
    SetIndexBuffer(1, buffDown);
    SetIndexBuffer(2, count);

    short_name = "OrderBlocks(" + timeFrameToString(TimeFrame) + "" + IntegerToString(FractalPeriod) + ")";
    IndicatorShortName(short_name);
    SetIndexLabel(0, "Up");
    SetIndexLabel(1, "Down");

    if (FractalPeriod <= 0) {
        Print("Wrong Fractals Period=", FractalPeriod);
        return INIT_PARAMETERS_INCORRECT;
    }

    SetIndexDrawBegin(0, FractalPeriod);
    SetIndexDrawBegin(1, FractalPeriod);

    m_ind_upper = 0;
    m_ind_lower = 0;

    indicatorFileName = WindowExpertName();
    TimeFrame = (enTimeFrames) timeFrameValue(TimeFrame);

    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    DeleteObjectsByPrefix(PREFIX);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
    if (id == CHARTEVENT_CHART_CHANGE) {
        if (Show_High_Low_Line) {
            DrawLineAndPrice();
            WindowRedraw();
        }
    }
}

int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[]) {
    if (Show_High_Low_Line) DrawLineAndPrice();

    int limit = MathMin(MathMax(rates_total - prev_calculated, FractalPeriod), rates_total - 2);
    count[0] = limit;
    if (TimeFrame != _Period) {
        limit = (int) MathMax(limit, MathMin(Bars - 1, _mtfCall(2, 0) * TimeFrame / _Period));
        for (int i = limit; i >= 0 && !_StopFlag; i--) {
            int y = iBarShift(NULL, TimeFrame, time[i]);
            int x = iBarShift(NULL, TimeFrame, time[i - 1]);
            if (x != y) {
                buffUp[i] = _mtfCall(0, y);
                buffDown[i] = _mtfCall(1, y);
            } else {
                buffUp[i] = EMPTY_VALUE;
                buffDown[i] = EMPTY_VALUE;
            }
        }
        return (rates_total);
    }

    if (rates_total <= FractalPeriod) return 0;

    limit = rates_total;
    if (prev_calculated > 0) {
        limit = rates_total - prev_calculated + FractalPeriod + 1;
    }
    ArraySetAsSeries(open, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(time, true);
    ArraySetAsSeries(buffUp, true);
    ArraySetAsSeries(buffDown, true);

    for (int i = limit - 1; i > 0; i--) {
        bool found_up = true;
        for (int j = i + 1; ((j < rates_total) && ((j - i) <= FractalPeriod)); j++) {
            if (low[j] < low[i]) {
                found_up = false;
                break;
            }
        }
        if (found_up) {
            for (int j = i - 1; (j > 0 && ((i - j) <= FractalPeriod)); j--) {
                if (low[j] < low[i]) {
                    found_up = false;
                    break;
                }
            }
        }
        if (found_up) {
            buffUp[i] = low[i];
            if (time[i] > m_level_updated && i != 0) {
                bool engulfing_ok = false;
                if (OBLineEngulfingType == engBody) {
                    double L = close[i] < open[i] ? close[i] : open[i];
                    double H = close[i] < open[i] ? open[i] : close[i];
                    engulfing_ok = close[i - 1] > open[i - 1] && open[i - 1] <= L && close[i - 1] > H;
                } else if (OBLineEngulfingType == engWick) {
                    engulfing_ok = low[i - 1] <= low[i] && high[i - 1] > high[i];
                }

                if (EngulfingHighlight && engulfing_ok) {
                    if (IsValidIndex(time, i + 1) && IsValidIndex(time, i - 1)) {
                        DrawRectangle(0, NameEngulfing, time[i + 1], MathMin(low[i], low[i - 1]), time[i - 1] + PeriodSeconds(), MathMax(high[i], high[i - 1]), EngulfingHighlightColorBull, 1, STYLE_SOLID);
                    }
                }

                if (!OBLineEngulfing) engulfing_ok = true;

                if (engulfing_ok) {
                    m_level_updated = time[i];
                    if (OBLineDraw) {
                        m_ind_lower++;
                        if (m_ind_lower > MAX_LINES) m_ind_lower = 1;

                        if (OBLineType == engBody) {
                            if (close[i] > open[i]) {
                                m_level = close[i];
                                if (close[1] > open[i]) {
                                    if (IsValidIndex(time, i + OBLineLength)) {
                                        DrawTL(0, NameUpper + IntegerToString(m_ind_lower), time[i], close[i], time[i] + PeriodSeconds() * OBLineLength, close[i], OBLineColorBull, OBLineWidth, OBLineStyle);
                                        DrawTL(0, NameLower + IntegerToString(m_ind_lower), time[i], open[i], time[i] + PeriodSeconds() * OBLineLength, open[i], OBLineColorBull, OBLineWidth, OBLineStyle);
                                        DrawText(0, NameUpper + IntegerToString(m_ind_lower) + "_text", time[i], close[i], "BL", clrRoyalBlue);
                                    }
                                }
                            } else {
                                m_level = open[i];
                                if (close[1] > close[i]) {
                                    if (IsValidIndex(time, i + OBLineLength)) {
                                        DrawTL(0, NameUpper + IntegerToString(m_ind_lower), time[i], open[i], time[i] + PeriodSeconds() * OBLineLength, open[i], OBLineColorBull, OBLineWidth, OBLineStyle);
                                        DrawTL(0, NameLower + IntegerToString(m_ind_lower), time[i], close[i], time[i] + PeriodSeconds() * OBLineLength, close[i], OBLineColorBull, OBLineWidth, OBLineStyle);
                                        DrawText(0, NameUpper + IntegerToString(m_ind_lower) + "_text", time[i], open[i], "BL", clrRoyalBlue);
                                    }
                                }
                            }
                        } else if (OBLineType == engWick) {
                            m_level = high[i];
                            if (close[1] > low[i]) {
                                if (IsValidIndex(time, i + OBLineLength)) {
                                    DrawTL(0, NameUpper + IntegerToString(m_ind_lower), time[i], high[i], time[i] + PeriodSeconds() * OBLineLength, high[i], OBLineColorBull, OBLineWidth, OBLineStyle);
                                    DrawTL(0, NameLower + IntegerToString(m_ind_lower), time[i], low[i], time[i] + PeriodSeconds() * OBLineLength, low[i], OBLineColorBull, OBLineWidth, OBLineStyle);
                                    DrawText(0, NameUpper + IntegerToString(m_ind_lower) + "_text", time[i], high[i], "BL", clrRoyalBlue);
                                }
                            }
                        }
                    }
                }
            }
        } else {
            buffUp[i] = EMPTY_VALUE;
            string nm = NameUpper + TimeToString(time[i]);
            if (ObjectFind(0, nm) >= 0) {
                color col = (color) ObjectGetInteger(0, nm, OBJPROP_COLOR);
                if (col == OBLineColorBull) ObjectDelete(0, nm);
            }
            nm = NameLower + TimeToString(time[i]);
            if (ObjectFind(0, nm) >= 0) {
                color col = (color) ObjectGetInteger(0, nm, OBJPROP_COLOR);
                if (col == OBLineColorBull) ObjectDelete(0, nm);
            }
        }

        bool found_down = true;
        for (int j = i + 1; ((j < rates_total) && ((j - i) <= FractalPeriod)); j++) {
            if (high[j] > high[i]) {
                found_down = false;
                break;
            }
        }
        if (found_down) {
            for (int j = i - 1; (j > 0 && ((i - j) <= FractalPeriod)); j--) {
                if (high[j] > high[i]) {
                    found_down = false;
                    break;
                }
            }
        }
        if (found_down) {
            buffDown[i] = high[i];
            if (time[i] > m_level_updated && i != 0) {
                bool engulfing_ok = false;
                if (OBLineEngulfingType == engBody) {
                    double L = close[i] < open[i] ? close[i] : open[i];
                    double H = close[i] < open[i] ? open[i] : close[i];
                    engulfing_ok = close[i - 1] < open[i - 1] && open[i - 1] >= H && close[i - 1] < L;
                } else if (OBLineEngulfingType == engWick) {
                    engulfing_ok = low[i - 1] < low[i] && high[i - 1] >= high[i];
                }
                if (EngulfingHighlight && engulfing_ok) {
                    if (IsValidIndex(time, i + 1) && IsValidIndex(time, i - 1)) {
                        DrawRectangle(0, NameEngulfing, time[i + 1], MathMin(low[i], low[i - 1]), time[i - 1] + PeriodSeconds(), MathMax(high[i], high[i - 1]), EngulfingHighlightColorBear, 1, STYLE_SOLID);
                    }
                }
                if (!OBLineEngulfing) engulfing_ok = true;
                if (engulfing_ok) {
                    m_level_updated = time[i];
                    if (OBLineDraw) {
                        m_ind_upper++;
                        if (m_ind_upper > MAX_LINES) m_ind_upper = 1;

                        if (OBLineType == engBody) {
                            if (close[i] > open[i]) {
                                m_level = -open[i];
                                if (close[1] < close[i]) {
                                    if (IsValidIndex(time, i + OBLineLength)) {
                                        DrawTL(0, NameUpper + IntegerToString(m_ind_upper), time[i], close[i], time[i] + PeriodSeconds() * OBLineLength, close[i], OBLineColorBear, OBLineWidth, OBLineStyle);
                                        DrawTL(0, NameLower + IntegerToString(m_ind_upper), time[i], open[i], time[i] + PeriodSeconds() * OBLineLength, open[i], OBLineColorBear, OBLineWidth, OBLineStyle);
                                        DrawText(0, NameUpper + IntegerToString(m_ind_upper) + "_text", time[i], close[i], "Sellside Liquidity", clrRed);
                                    }
                                }
                            } else {
                                m_level = -close[i];
                                if (close[1] < open[i]) {
                                    if (IsValidIndex(time, i + OBLineLength)) {
                                        DrawTL(0, NameUpper + IntegerToString(m_ind_upper), time[i], open[i], time[i] + PeriodSeconds() * OBLineLength, open[i], OBLineColorBear, OBLineWidth, OBLineStyle);
                                        DrawTL(0, NameLower + IntegerToString(m_ind_upper), time[i], close[i], time[i] + PeriodSeconds() * OBLineLength, close[i], OBLineColorBear, OBLineWidth, OBLineStyle);
                                        DrawText(0, NameUpper + IntegerToString(m_ind_upper) + "_text", time[i], open[i], "Sellside Liquidity", clrRed);
                                    }
                                }
                            }
                        } else if (OBLineType == engWick) {
                            m_level = -low[i];
                            if (close[1] < high[i]) {
                                if (IsValidIndex(time, i + OBLineLength)) {
                                    DrawTL(0, NameUpper + IntegerToString(m_ind_upper), time[i], high[i], time[i] + PeriodSeconds() * OBLineLength, high[i], OBLineColorBear, OBLineWidth, OBLineStyle);
                                    DrawTL(0, NameLower + IntegerToString(m_ind_upper), time[i], low[i], time[i] + PeriodSeconds() * OBLineLength, low[i], OBLineColorBear, OBLineWidth, OBLineStyle);
                                    DrawText(0, NameUpper + IntegerToString(m_ind_upper) + "_text", time[i], high[i], "Sellside Liquidity", clrRed);
                                }
                            }
                        }
                    }
                }
            }
        } else {
            buffDown[i] = EMPTY_VALUE;
            string nm = NameUpper + TimeToString(time[i]);
            if (ObjectFind(0, nm) >= 0) {
                color col = (color) ObjectGetInteger(0, nm, OBJPROP_COLOR);
                if (col == OBLineColorBear) ObjectDelete(0, nm);
            }
            nm = NameLower + TimeToString(time[i]);
            if (ObjectFind(0, nm) >= 0) {
                color col = (color) ObjectGetInteger(0, nm, OBJPROP_COLOR);
                if (col == OBLineColorBear) ObjectDelete(0, nm);
            }
        }
    }

    bool something_removed = true;
    while (something_removed) {
        something_removed = false;
        int tot = ObjectsTotal();
        for (int j = 0; j < tot; j++) {
            string nm = ObjectName(j);
            if (StringFind(nm, PREFIX) >= 0) {
                color col = (color) ObjectGetInteger(0, nm, OBJPROP_COLOR);
                if (col == OBLineColorBear && StringFind(nm, NameUpper) >= 0) {
                    double price = ObjectGetDouble(0, nm, OBJPROP_PRICE);
                    int shift = iBarShift(Symbol(), PERIOD_CURRENT, ObjectGetInteger(0, nm, OBJPROP_TIME));
                    string nmm = nm;
                    StringReplace(nmm, NameUpper, NameLower);
                    double price_nmm = ObjectGetDouble(0, nmm, OBJPROP_PRICE);
                    if (shift > 0) {
                        int stage = 0;
                        bool ale = false;
                        for (int i = shift - 1; i >= 0; i--) {
                            if (close[i] > price) {
                                ObjectDelete(0, nm);
                                ObjectDelete(nmm);
                                something_removed = true;
                                break;
                            }
                            if (high[i] > price_nmm && stage == 1) {
                                stage = 2;
                                if (i == 0 && ObjectGetInteger(0, nmm, OBJPROP_WIDTH) == OBLineWidth) ale = true;
                            }
                            if (close[i] < price_nmm && stage == 0) {
                                stage = 1;
                            }
                        }
                        if (something_removed) break;
                        else {
                            if (stage == 2) {
                                ObjectSetInteger(0, nmm, OBJPROP_WIDTH, OBLineWidth + 2);
                                if (ale) Alarm("Bear OB is touched at the price " + DoubleToString(price_nmm, Digits));
                            }
                        }
                    }
                } else if (col == OBLineColorBull && StringFind(nm, NameLower) >= 0) {
                    double price = ObjectGetDouble(0, nm, OBJPROP_PRICE);
                    int shift = iBarShift(Symbol(), PERIOD_CURRENT, ObjectGetInteger(0, nm, OBJPROP_TIME));
                    string nmm = nm;
                    StringReplace(nmm, NameLower, NameUpper);
                    double price_nmm = ObjectGetDouble(0, nmm, OBJPROP_PRICE);
                    if (shift > 0) {
                        int stage = 0;
                        bool ale = false;
                        for (int i = shift - 1; i >= 0; i--) {
                            if (close[i] < price) {
                                ObjectDelete(0, nm);
                                ObjectDelete(nmm);
                                something_removed = true;
                                break;
                            }
                            if (low[i] < price_nmm && stage == 1) {
                                stage = 2;
                                if (i == 0 && ObjectGetInteger(0, nmm, OBJPROP_WIDTH) == OBLineWidth) ale = true;
                            }
                            if (close[i] > price_nmm && stage == 0) {
                                stage = 1;
                            }
                        }
                        if (something_removed) break;
                        else {
                            if (stage == 2) {
                                ObjectSetInteger(0, nmm, OBJPROP_WIDTH, OBLineWidth + 2);
                                if (ale) Alarm("Bull OB is touched at the price " + DoubleToString(price_nmm, Digits));
                            }
                        }
                    }
                }
            }
        }
    }

    WindowRedraw();
    return rates_total;
}

void DrawLineAndPrice() {
    for (int i = 0; i < Bars; i++) {
        //low side
        if (buffUp[i] != EMPTY_VALUE) {
            DrawTL(0, PREFIX + "Low_H_Line", Time[Bars - 20], Low[i], Time[0] + PeriodSeconds() * OBLineLength, Low[i], OBLineColorBull, OBLineWidth, OBLineStyle);
            DrawPrice(PREFIX + "lowprice", Time[0], Low[i], Color_Price_Lable_Low, Price_Lable_Font_Size, " " + DoubleToStr(Low[i], Digits), 0);
            break;
        }
    }

    for (int i = 0; i < Bars; i++) {
        //high side
        if (buffDown[i] != EMPTY_VALUE) {
            DrawTL(0, PREFIX + "High_H_Line", Time[Bars - 20], High[i], Time[0] + PeriodSeconds() * OBLineLength, High[i], OBLineColorBear, OBLineWidth, OBLineStyle);
            DrawPrice(PREFIX + "Highprice", Time[0], High[i], Color_Price_Label_High, Price_Lable_Font_Size, " " + DoubleToStr(High[i], Digits), -17);
            break;
        }
    }
}

void DrawPrice(string name, datetime time1, double price1, color col, int fontSize, string text, int shift) {
    int x, y;

    // Needed only for y, x is derived from the chart width.
    ChartTimePriceToXY(0, 0, time1, price1, x, y);
    DrawLabel(name, x, y + shift, text, fontSize, "Arial", col, DoubleToStr(price1, Digits));
}

void DrawLabel(string name, int x, int y, string label, int size = 9, string font = "Arial", color clr = DimGray, string tooltip = "") {
    if (ObjectFind(name) < 0) {
        ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
    }

    ObjectSetText(name, label, size, font, clr);
    ObjectSet(name, OBJPROP_CORNER, 0);
    ObjectSet(name, OBJPROP_XDISTANCE, x);
    ObjectSet(name, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, name, OBJPROP_TOOLTIP, tooltip);
}

void DrawHLineObject(string lname, double dValue, color clr) {
    string name = lname;

    if (ObjectFind(name) == -1)
        ObjectCreate(name, OBJ_HLINE, 0, Time[0], dValue);

    ObjectMove(name, 0, TimeCurrent(), dValue);
    ObjectSet(name, OBJPROP_STYLE, STYLE_DOT);
    ObjectSet(name, OBJPROP_COLOR, clr);
    ObjectSet(name, OBJPROP_WIDTH, 1);
}

void UpdateHL(long cid, string nm, color col, int width, ENUM_LINE_STYLE style) {
    if (ObjectFind(cid, nm) >= 0) {
        ObjectSetInteger(cid, nm, OBJPROP_COLOR, col);
        ObjectSetInteger(cid, nm, OBJPROP_WIDTH, width);
        ObjectSetInteger(cid, nm, OBJPROP_STYLE, style);
    }
}

void DrawRectangle(long cid, string nm, datetime dt1, double pr1, datetime dt2, double pr2, color col, int width, ENUM_LINE_STYLE style) {
    if (ObjectFind(cid, nm) < 0) {
        ObjectCreate(cid, nm, OBJ_RECTANGLE, 0, dt1, pr1, dt2, pr2);
    }
    if (ObjectFind(cid, nm) >= 0) {
        ObjectSetInteger(cid, nm, OBJPROP_COLOR, col);
        ObjectSetInteger(cid, nm, OBJPROP_WIDTH, width);
        ObjectSetInteger(cid, nm, OBJPROP_STYLE, style);
        ObjectSetInteger(cid, nm, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(cid, nm, OBJPROP_SELECTED, false);
        ObjectSetInteger(cid, nm, OBJPROP_BACK, true);
        ObjectSetInteger(cid, nm, OBJPROP_RAY, false);
        ObjectMove(cid, nm, 0, dt1, pr1);
        ObjectMove(cid, nm, 1, dt2, pr2);
    }
}

void Alarm(string body) {
    string shortName = "OrderBlocks " + Symbol() + " " + HumanCompressionShort(Period()) + " ";
    if (soundAlert) {
        PlaySound("alert.wav");
    }
    if (popupAlert) {
        Alert(shortName, body);
    }
    if (emailAlert) {
        SendMail("From " + shortName, shortName + body);
    }
    if (pushAlert) {
        SendNotification(shortName + body);
    }
}

void DrawTL(long cid, string nm, datetime dt1, double pr1, datetime dt2, double pr2, color col, int width, ENUM_LINE_STYLE style) {
    if (ObjectFind(cid, nm) < 0) {
        ObjectCreate(cid, nm, OBJ_TREND, 0, dt1, pr1, dt2, pr2);
    }
    if (ObjectFind(cid, nm) >= 0) {
        ObjectSetInteger(cid, nm, OBJPROP_COLOR, col);
        ObjectSetInteger(cid, nm, OBJPROP_WIDTH, width);
        ObjectSetInteger(cid, nm, OBJPROP_STYLE, style);
        ObjectSetInteger(cid, nm, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(cid, nm, OBJPROP_SELECTED, false);
        ObjectSetInteger(cid, nm, OBJPROP_RAY, false);
        ObjectSetInteger(cid, nm, OBJPROP_RAY_RIGHT, false);
        ObjectSetInteger(cid, nm, OBJPROP_BACK, false);
        ObjectMove(cid, nm, 0, dt1, pr1);
        ObjectMove(cid, nm, 1, dt2, pr2);
    }
}

void DeleteObjectsByPrefix(string pref) {
    bool something_removed = true;
    while (something_removed) {
        something_removed = false;
        int tot = ObjectsTotal();
        for (int i = 0; i < tot; i++) {
            string nm = ObjectName(i);
            if (StringFind(nm, pref) >= 0) {
                ObjectDelete(nm);
                something_removed = true;
                break;
            }
        }
    }
}

string HumanCompressionShort(int per) {
    if (per == 0) per = Period();
    switch (per) {
        case PERIOD_M1:
            return ("M1");
        case PERIOD_M5:
            return ("M5");
        case PERIOD_M15:
            return ("M15");
        case PERIOD_M30:
            return ("M30");
        case PERIOD_H1:
            return ("H1");
        case PERIOD_H4:
            return ("H4");
        case PERIOD_D1:
            return ("D1");
        case PERIOD_W1:
            return ("W1");
        case PERIOD_MN1:
            return ("MN1");
    }
    return ("M" + IntegerToString(per));
}

string sTfTable[] = {"M1", "M5", "M15", "M30", "H1", "H4", "D1", "W1", "MN"};
int iTfTable[] = {1, 5, 15, 30, 60, 240, 1440, 10080, 43200};

string timeFrameToString(int tf) {
    for (int i = ArraySize(iTfTable) - 1; i >= 0; i--)
        if (tf == iTfTable[i]) return (sTfTable[i]);
    return ("");
}

int timeFrameValue(int _tf) {
    int add = (_tf >= 0) ? 0 : MathAbs(_tf);
    if (add != 0) _tf = _Period;
    int size = ArraySize(iTfTable);
    int i = 0;
    for (; i < size; i++) if (iTfTable[i] == _tf) break;
    if (i == size) return (_Period);
    return (iTfTable[(int) MathMin(i + add, size - 1)]);
}

void DrawText(long chart_id, string name, datetime time, double price, string text, color text_color) {
    if (ObjectFind(chart_id, name) < 0) {
        ObjectCreate(chart_id, name, OBJ_TEXT, 0, time, price);
    }
    ObjectSetInteger(chart_id, name, OBJPROP_COLOR, text_color);
    ObjectSetInteger(chart_id, name, OBJPROP_FONTSIZE, 10);
    ObjectSetString(chart_id, name, OBJPROP_TEXT, text);
    ObjectSetInteger(chart_id, name, OBJPROP_CORNER, CORNER_LEFT_LOWER);
    ObjectSetInteger(chart_id, name, OBJPROP_XDISTANCE, 5);
    ObjectSetInteger(chart_id, name, OBJPROP_YDISTANCE, 5);
}

bool IsValidIndex(const datetime &time[], int index)
{
    return (index >= 0 && index < ArraySize(time));
}
