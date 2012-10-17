/* Nerr SmartTrader - Multi Broker Trader - Slave
 * 
 * @History
 * v0.0.0  [dev] 2012-09-03 init.
 * v0.0.1  [dev] 2012-10-15 add drawFibo() and delFibo() func.
 * v0.0.2  [dev] 2012-10-17 rename getLots() func to caluLots(); add getG8Index() func use to auto select index by symbol name.
 * v0.0.3  [dev] 2012-10-17 confirm main flow path in start() func.
 */

//-- property info
#property copyright "Copyright ? 2012 Nerrsoft.com"
#property link 		"http://nerrsoft.com"

//-- extern var
extern string 	indicatorparam = "--------trade param--------";
extern double 	lots = 1;
extern int 		stoploss = 30;
extern double 	g8thold = 3;
extern int 		historykline = 15;
extern int 		magicnumber = 911;
extern string 	maceindicatorparam = "--------indicator param of macd--------";
extern int 		macdfastema = 12;
extern int 		macdslowema = 26;
extern int 		macesma = 9;
extern string 	kdindicatorparam = "--------indicator param of kd--------";
extern int 		kperiod = 5;
extern int 		dperiod = 3;
extern int 		kdslowing = 3;
extern string 	g8indicatorparam = "--------indicator param of g8 usd--------";

//-- define var
#define EUR 0
#define GBP 1
#define AUD 2
#define CAD 3
#define CHF 4
#define JPY 5
#define USD 6
#define NZD 7

//-- global var
string pair_a, pair_b;
int index_a, index_b;

//-- init
int init()
{
	pair_a = StringSubstr(Symbol(), 0, 3);
	pair_b = StringSubstr(Symbol(), 3, 3);

	index_a = getG8Index(pair_a);
	index_b = getG8Index(pair_b);

	if(index_a>7 || index_b>7)
		outputLog("Do not support current symbol!", "ERROR");

	return(0);
}

//-- deinit
int deinit()
{
	return(0);
}

//-- start
int start()
{
	int direction = 9;

	double currency_a = iCustom(NULL, -1, "G8_USD_v1.1", index_a, 0);
	double currency_a = iCustom(NULL, -1, "G8_USD_v1.1", index_b, 0);

	double g8diff = MathAbs(MathAbs(currency_a) - MathAbs(currency_b));

	if(g8diff >= g8thold)
	{
		if(currency_a < current_b)
			direction = 0; //-- 0-buy; 1-sell; 9-nosignal;
		else
			direction = 1;
	}

	//--
	if(direction==0 || direction==1)
	{
		//-- open order if no order, open order if g8diff is bigger than last one and change orders traget.
		if(OrdersTotal()==0)
		{
			//openOrder();
		}
		else
		{
			double oldG8Diff = 0;
			for(int i = 0; i < OrdersTotal(); i++)
			{
				if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
				{
					// todo - no select order
				}
				else
				{
					if(OrderMagicNumber() == MagicNumber && OrderSymbol()==Symbol())
					{
						if(StrToDouble(OrderComment()) > oldG8Diff)
						{
							oldG8Diff = StrToDouble(OrderComment());
						}
					}
				}
			}

			if(oldG8Diff==0)
			{
				//openOrder();
			}
			else if(oldG8Diff > 0 && (oldG8Diff + 0) <= g8diff)
			{
				//openOrder();
				//adjustOrderTP(); [redraw fibonacci]
			}
		}
	}
}

//-- calculat lots by kd(Stochastic)
/*
	look you kd

	if kd>75. oversold you maybe use 1.5-2% risk
	if kd<75 not oversold you maybe use 0.5-1% risk

	like 500$ in the example.20 pips stop loss

	500*1%=5$/20pips=0.025 lots
*/
double calcuLots()
{
	double lots, rate, kd;

	kd = iCustom(NULL, 0, "Stochastic", kperiod, dperiod, kdslowing, 0, 0);

	if(kd>75)
		rate = 0.01;
	else
		rate = 0.005;

	lots = (AccountEquity() * rate) / stoploss;
	lots = StrToDouble(DoubleToStr(lots, 2));

	return(lots);
}


//-- check margin safe or not
bool checkMarginSafe(int cmd, double lots)
{
	double freemargin = AccountFreeMarginCheck(Symbol(), cmd, lots);

	//-- if free margin less than 0 then return false
	if(freemargin<=0)
		return(false);

	//-- margin level = equity / (equity - free margin)
	double marginlevel = AccountEquity() / (AccountEquity() - freemargin);

	//-- safe margin level set to 200%
	if(marginlevel>2)
		return(true);
	else
		return(false);
}


//-- draw a fibonacci
void drawFibo(int ordertype, int ticket)
{
	string objName = "fibo_" + ticket;
	datetime fiboDate[2];
	double fiboValue[2];

	//-- get second 
	fiboDate[1] = iTime(symbol(), 0, 0);
	if(ordertype==0)
		fiboValue[1] = iLow(symbol(), 0, 0);
	else
		fiboValue[1] = iHigh(symbol(), 0, 0);

	if(ObjectFind(objName)<0)
	{
		ObjectCreate(objName, OBJ_FIBO, 0, fiboDate[0], fiboValue[0], fiboDate[1], fiboValue[1]);
	}
}

//-- delete a fibonacci
bool delFibo(int ticket)
{
	return(ObjectDelete("fibo_" + ticket));
}

//- get pair's index in G8 indicator
int getG8Index(string pair)
{
	if(pair=="EUR")
		return(EUR);
	else if(pair=="GBP")
		return(GBP);
	else if(pair=="USD")
		return(USD);
	else if(pair=="AUD")
		return(AUD);
	else if(pair=="NZD")
		return(NZD);
	else if(pair=="CAD")
		return(CAD);
	else if(pair=="CHF")
		return(CHF);
	else if(pair=="JPY")
		return(JPY);
	else
		return(9);
}

//- output trade info (log)
void outputLog(string logtext, string type="Information")
{
	string text = ">>>" + type + ":" + logtext;
	Print (text);
}