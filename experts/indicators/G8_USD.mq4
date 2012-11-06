/*
  Modified by Leon Zhuang leon@nerrsoft.com
  v1.4 - change extern var "show_labels" location to the first, use to call it in EA easier.
  v1.5 - added 4 indicator_level.

  Modified by Dr Bean
  v1.3 - Added auto pair detection
  v1.2 - Added Alerts
  v1.1 - Added Labels, Added Currency Selection, Added Pair Strings
  Updated to G8_USD_v1.1 - by netFX (ASN)
   --Added NZD which is major currency with NZDUSD the highest average PIPs/day range
*/

#property indicator_separate_window
#property indicator_buffers 8
#property indicator_color1 Aqua
#property indicator_width1 2
#property indicator_color2 Blue
#property indicator_width2 2
#property indicator_color3 Yellow
#property indicator_width3 2
#property indicator_color4 Green
#property indicator_width4 2
#property indicator_color5 Magenta
#property indicator_width5 2
#property indicator_color6 Red
#property indicator_width6 2
#property indicator_color7 SaddleBrown
#property indicator_width7 2
#property indicator_color8 LightSlateGray
#property indicator_width8 2
#property indicator_level1 0.0
#property indicator_level2 1.0
#property indicator_level3 -1.0
#property indicator_level4 2.0
#property indicator_level5 -2.0
#property indicator_level6 3.0
#property indicator_level7 -3.0

#define EUR 0
#define GBP 1
#define AUD 2
#define CAD 3
#define CHF 4
#define JPY 5
#define USD 6
#define NZD 7
#define ALARM_OFF 0
#define ALARM_ON 1
#define ALARM_RESET 2


extern bool   show_labels = true;  // Show Colored Labels for currencies displayed in chart.

extern int    SMA_variable = 1;
extern int    SMA_base = 10;
extern int    SMA_unit = 60;

extern string display_currencies="";
extern bool   auto_select = true;  // Automatically select current pair to display in chart
extern bool   show_eur = true;     // Show EUR in chart. Must have 'auto_select = false'.
extern bool   show_gbp = true;     // Show GBP in chart. Must have 'auto_select = false'.
extern bool   show_aud = true;     // Show AUD in chart. Must have 'auto_select = false'.
extern bool   show_cad = true;     // Show CAD in chart. Must have 'auto_select = false'.
extern bool   show_chf = true;     // Show CHF in chart. Must have 'auto_select = false'.
extern bool   show_jpy = true;     // Show JPY in chart. Must have 'auto_select = false'.
extern bool   show_usd = true;     // Show USD in chart. Must have 'auto_select = false'.
extern bool   show_nzd = true;     // Show USD in chart. Must have 'auto_select = false'.

extern string alerts="";
extern double alert_level=1.0;
extern double alert_resetzone=0.05; // After an alert, the currency value must go below alert_level-alert_resetzone inorder for alerts to be reactivated
extern int    alert_timeout=300;    // After an alert, alerts on the currency are deactivated for alert_timeout seconds
extern bool   alert_popup=false;    // Enable alert popup dialog.
extern bool   alert_email=false;    // Enable alert email.
extern bool   alert_eur = true;
extern bool   alert_gbp = true;
extern bool   alert_aud = true;
extern bool   alert_cad = true;
extern bool   alert_chf = true;
extern bool   alert_jpy = true;
extern bool   alert_usd = true;
extern bool   alert_nzd = true;

extern string pair_strings="";       // Change these to reflect the strings your uses to identify the pairs
extern string eurusd_id = "EURUSD";  // The defaults are the standard values used by most brokers
extern string gpbusd_id = "GBPUSD";
extern string audusd_id = "AUDUSD";
extern string usdcad_id = "USDCAD";
extern string usdchf_id = "USDCHF";
extern string usdjpy_id = "USDJPY";
extern string nzdusd_id = "NZDUSD";

double eur_buf[];
double gbp_buf[];
double aud_buf[];
double cad_buf[];
double chf_buf[];
double jpy_buf[];
double usd_buf[];
double nzd_buf[];
string indicator_name;
bool   labels_shown=false;
int alert_status[8];
int  alert_timer[8];
bool startup;

int init() {
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID);
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID);
   SetIndexStyle(2, DRAW_LINE, STYLE_SOLID);
   SetIndexStyle(3, DRAW_LINE, STYLE_SOLID);
   SetIndexStyle(4, DRAW_LINE, STYLE_SOLID);
   SetIndexStyle(5, DRAW_LINE, STYLE_SOLID);
   SetIndexStyle(6, DRAW_LINE, STYLE_SOLID);
   SetIndexStyle(7, DRAW_LINE, STYLE_SOLID);
   SetIndexBuffer(0, eur_buf);
   SetIndexBuffer(1, gbp_buf);
   SetIndexBuffer(2, aud_buf);
   SetIndexBuffer(3, cad_buf);
   SetIndexBuffer(4, chf_buf);
   SetIndexBuffer(5, jpy_buf);
   SetIndexBuffer(6, usd_buf);
   SetIndexBuffer(7, nzd_buf);
   SetIndexLabel(0, "EUR");
   SetIndexLabel(1, "GBP");
   SetIndexLabel(2, "AUD");
   SetIndexLabel(3, "CAD");
   SetIndexLabel(4, "CHF");
   SetIndexLabel(5, "JPY");
   SetIndexLabel(6, "USD");
   SetIndexLabel(7, "NZD");
   SMA_variable = SMA_variable * SMA_unit / Period();
   SMA_base = SMA_base * SMA_unit / Period();
   indicator_name="G8_USD(" + SMA_variable + "," + SMA_base + ")";
   IndicatorShortName(indicator_name);
   IndicatorDigits(4);
   auto_select_pair();
   labels_shown=false;
   startup=true;
   return (0);
}

int deinit() {
  for(int i=ObjectsTotal()-1; i>-1; i--)
    if (StringFind(ObjectName(i),"G8_")>=0)  ObjectDelete(ObjectName(i));
  return(0);
}

int start() {   
   double ma_avg[8];
   int counted_bars = IndicatorCounted();
   if (counted_bars > 0) counted_bars--;
   int limit = Bars - counted_bars;
   
   if (labels_shown==false && show_labels==true) show_currency_labels();
   
   for (int i = 0; i < limit; i++) {
      if (SMA_variable == 0) {
         ma_avg[0] = iClose(eurusd_id, 0, i) / iMA(eurusd_id, 0, SMA_base, 0, MODE_SMA, PRICE_CLOSE, i);
         ma_avg[1] = iClose(gpbusd_id, 0, i) / iMA(gpbusd_id, 0, SMA_base, 0, MODE_SMA, PRICE_CLOSE, i);
         ma_avg[2] = iClose(audusd_id, 0, i) / iMA(audusd_id, 0, SMA_base, 0, MODE_SMA, PRICE_CLOSE, i);
         ma_avg[3] = iMA(usdcad_id, 0, SMA_base, 0, MODE_SMA, PRICE_CLOSE, i) / iClose(usdcad_id, 0, i);
         ma_avg[4] = iMA(usdchf_id, 0, SMA_base, 0, MODE_SMA, PRICE_CLOSE, i) / iClose(usdchf_id, 0, i);
         ma_avg[5] = iMA(usdjpy_id, 0, SMA_base, 0, MODE_SMA, PRICE_CLOSE, i) / iClose(usdjpy_id, 0, i);
         ma_avg[6] = iClose(nzdusd_id, 0, i) / iMA(nzdusd_id, 0, SMA_base, 0, MODE_SMA, PRICE_CLOSE, i);
      } else {
         if (SMA_variable > 0) {
            ma_avg[0] = iMA(eurusd_id, 0, SMA_variable, 0, MODE_SMA, PRICE_CLOSE, i) / iMA(eurusd_id, 0, SMA_base, 0, MODE_SMA, PRICE_CLOSE, i);
            ma_avg[1] = iMA(gpbusd_id, 0, SMA_variable, 0, MODE_SMA, PRICE_CLOSE, i) / iMA(gpbusd_id, 0, SMA_base, 0, MODE_SMA, PRICE_CLOSE, i);
            ma_avg[2] = iMA(audusd_id, 0, SMA_variable, 0, MODE_SMA, PRICE_CLOSE, i) / iMA(audusd_id, 0, SMA_base, 0, MODE_SMA, PRICE_CLOSE, i);
            ma_avg[3] = iMA(usdcad_id, 0, SMA_base, 0, MODE_SMA, PRICE_CLOSE, i) / iMA(usdcad_id, 0, SMA_variable, 0, MODE_SMA, PRICE_CLOSE, i);
            ma_avg[4] = iMA(usdchf_id, 0, SMA_base, 0, MODE_SMA, PRICE_CLOSE, i) / iMA(usdchf_id, 0, SMA_variable, 0, MODE_SMA, PRICE_CLOSE, i);
            ma_avg[5] = iMA(usdjpy_id, 0, SMA_base, 0, MODE_SMA, PRICE_CLOSE, i) / iMA(usdjpy_id, 0, SMA_variable, 0, MODE_SMA, PRICE_CLOSE, i);
            ma_avg[6] = iMA(nzdusd_id, 0, SMA_variable, 0, MODE_SMA, PRICE_CLOSE, i) / iMA(nzdusd_id, 0, SMA_base, 0, MODE_SMA, PRICE_CLOSE, i);
         }
      }

      if (show_eur) {
        eur_buf[i] = ma_avg[0] * (100 / ma_avg[1] + 100.0 + 100 / ma_avg[2] + 100 / ma_avg[3] + 100 / ma_avg[4] + 100 / ma_avg[5]+ 100 / ma_avg[6]) - 700.0;
        if (alert_eur) alert_check(EUR, eur_buf[i]);
      }
      if (show_gbp) {
         gbp_buf[i] = ma_avg[1] * (100 / ma_avg[0] + 100.0 + 100 / ma_avg[2] + 100 / ma_avg[3] + 100 / ma_avg[4] + 100 / ma_avg[5]+ 100 / ma_avg[6]) - 700.0;
         if (alert_gbp) alert_check(GBP, gbp_buf[i]);
      }
      if (show_aud) {
         aud_buf[i] = ma_avg[2] * (100 / ma_avg[0] + 100.0 + 100 / ma_avg[1] + 100 / ma_avg[3] + 100 / ma_avg[4] + 100 / ma_avg[5]+ 100 / ma_avg[6]) - 700.0;
         if (alert_aud) alert_check(AUD, aud_buf[i]);
      }
      if (show_cad) {
         cad_buf[i] = ma_avg[3] * (100 / ma_avg[0] + 100.0 + 100 / ma_avg[1] + 100 / ma_avg[2] + 100 / ma_avg[4] + 100 / ma_avg[5]+ 100 / ma_avg[6]) - 700.0;
         if (alert_cad) alert_check(CAD, cad_buf[i]);
      }
      if (show_chf) {
         chf_buf[i] = ma_avg[4] * (100 / ma_avg[0] + 100.0 + 100 / ma_avg[1] + 100 / ma_avg[2] + 100 / ma_avg[3] + 100 / ma_avg[5]+ 100 / ma_avg[6]) - 700.0;
         if (alert_chf) alert_check(CHF, chf_buf[i]);
      }
      if (show_jpy) {
         jpy_buf[i] = ma_avg[5] * (100 / ma_avg[0] + 100.0 + 100 / ma_avg[1] + 100 / ma_avg[2] + 100 / ma_avg[3] + 100 / ma_avg[4]+ 100 / ma_avg[6]) - 700.0;
         if (alert_jpy) alert_check(JPY, jpy_buf[i]);
      }
      if (show_nzd) {
         nzd_buf[i] = ma_avg[6] * (100 / ma_avg[0] + 100.0 + 100 / ma_avg[1] + 100 / ma_avg[2] + 100 / ma_avg[3] + 100 / ma_avg[4]+ 100 / ma_avg[5]) - 700.0;
         if (alert_nzd) alert_check(NZD, nzd_buf[i]);
      }
      if (show_usd) {
         usd_buf[i] = 100 / ma_avg[0] + 100 / ma_avg[1] + 100 / ma_avg[2] + 100 / ma_avg[3] + 100 / ma_avg[4] + 100 / ma_avg[5] + 100 / ma_avg[6]- 700.0;
         if (alert_usd) alert_check(USD, usd_buf[i]);
      }

   }
   startup=false;
   return (0);
}

void show_currency_labels(){
  int i;
  
  for(i=ObjectsTotal()-1; i>-1; i--)
    if (StringFind(ObjectName(i),"G8_")>=0)  ObjectDelete(ObjectName(i));
  
  i=0;
  
  if (show_eur) {
    currency_label("EUR",i,indicator_color1); 
    i++;
  }
  if (show_gbp) {
    currency_label("GBP",i,indicator_color2);
    i++;
  }
  if (show_aud) {
    currency_label("AUD",i,indicator_color3);
    i++;
  } 
  if (show_cad) {
    currency_label("CAD",i,indicator_color4);
    i++;
  }
  if (show_chf) {
    currency_label("CHF",i,indicator_color5);
    i++;
  }
  if (show_jpy) {
    currency_label("JPY",i,indicator_color6);
    i++;
  }
  if (show_usd) {
    currency_label("USD",i,indicator_color7);
    i++;
  }
  if (show_nzd) {
    currency_label("NZD",i,indicator_color8);
    i++;
  }
}
   
void currency_label(string currency, int txt_pos, color txt_color) {
  string obj_id;
  int win_idx=WindowFind(indicator_name);
  
  if (win_idx>0) 
    labels_shown=true;

  obj_id="G8_"+currency;
  if(ObjectFind(obj_id)<0) ObjectCreate(obj_id, OBJ_LABEL, win_idx, 0, 0);  
  ObjectSet(obj_id, OBJPROP_XDISTANCE, 4+txt_pos*35);
  ObjectSet(obj_id, OBJPROP_YDISTANCE, 15);
  ObjectSetText(obj_id, currency, 9, "Arial Black", txt_color);
}

void alert_check(int currency, double value) {
string message;
    if (startup==true) return(0);
    
    if (alert_status[currency]==ALARM_OFF && MathAbs(value)>=alert_level ) {
      alert_timer[currency]=GetTickCount()+alert_timeout*1000;
      alert_status[currency]=ALARM_ON;
      message="G8_USD: "+CurrencyToStr(currency)+" has reached level ±"+DoubleToStr(alert_level,1);
      if (alert_popup) 
         Alert(message);      
      if (alert_email) 
         SendMail( message, "MT4 Alert!\n" + TimeToStr(TIME_DATE|TIME_SECONDS )+"\n"+message);
    }
    else if (alert_status[currency]==ALARM_ON && alert_timer[currency]<GetTickCount()) {
      alert_status[currency]=ALARM_RESET;
    }    
    else if (alert_status[currency]==ALARM_RESET && MathAbs(value)<(alert_level-alert_resetzone)) {
      alert_status[currency]=ALARM_OFF;
      alert_timer[currency]=0;
    }
  return(0);
}

string CurrencyToStr(int currency) {
   switch(currency) {
     case EUR: return("EUR");
     case GBP: return("GBP");
     case AUD: return("AUD");
     case CAD: return("CAD");
     case CHF: return("CHF");
     case JPY: return("JPY");
     case USD: return("USD");
     case NZD: return("NZD");     
   }
   return("NA");
}

void auto_select_pair() {
string pair_1,pair_2;

   if (auto_select==true) {
     pair_1=StringSubstr(Symbol(),0,3);
     pair_2=StringSubstr(Symbol(),3,3);
     
     if (pair_1==CurrencyToStr(EUR) || pair_2==CurrencyToStr(EUR)) show_eur = true;
     else show_eur = false;
     
     if (pair_1==CurrencyToStr(GBP) || pair_2==CurrencyToStr(GBP)) show_gbp = true;
     else show_gbp = false;
       
     if (pair_1==CurrencyToStr(AUD) || pair_2==CurrencyToStr(AUD)) show_aud = true;
     else show_aud = false;
     
     if (pair_1==CurrencyToStr(CAD) || pair_2==CurrencyToStr(CAD)) show_cad = true;
     else show_cad = false;
     
     if (pair_1==CurrencyToStr(CHF) || pair_2==CurrencyToStr(CHF)) show_chf = true;
     else show_chf = false;
     
     if (pair_1==CurrencyToStr(JPY) || pair_2==CurrencyToStr(JPY)) show_jpy = true;
     else show_jpy = false;
     
     if (pair_1==CurrencyToStr(USD) || pair_2==CurrencyToStr(USD)) show_usd = true;
     else show_usd = false;   
     
     if (pair_1==CurrencyToStr(NZD) || pair_2==CurrencyToStr(NZD)) show_nzd = true;
     else show_nzd = false;   
   }    
   return(0);
}