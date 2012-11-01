/* Nerr SmartTrader - Fibonacci Retracement Trading System
 * 
 * @History
 * v0.0.0  [dev] 2012-09-03 init.
 * v0.0.1  [dev] 2012-10-15 add drawFibo() and delFibo() func.
 * v0.0.2  [dev] 2012-10-17 rename getLots() func to caluLots(); add getG8Index() func use to auto select index by symbol name.
 * v0.0.3  [dev] 2012-10-17 confirm main flow path in start() func.
 * v0.0.4  [dev] 2012-10-23 default stop loss change to 20 pips; change g8thold to 4;
 * v0.0.5  [dev] 2012-10-31 add closeOrder func;
 * v0.0.6  [dev] 2012-10-31 add getFiboPrice() func use to get fibonacci price;
 * v0.0.7  [dev] 2012-11-01 fix some bug and make it runable;
 */

//-- property info
#property copyright "Copyright ? 2012 Nerrsoft.com"
#property link 		"http://nerrsoft.com"

//-- extern var
extern string 	indicatorparam = "--------trade param--------";
extern double 	lots = 0.01;
extern int 		stoploss = 30;
extern double 	g8thold = 2;
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

//-- start  **not complete**
int start()
{
	int direction = 9;

	double currency_a = iCustom(NULL, -1, "G8_USD_v1.1", index_a, 0);
	double currency_b = iCustom(NULL, -1, "G8_USD_v1.1", index_b, 0);

	double g8diff = MathAbs(currency_a - currency_b);

	//--
	if(g8diff >= g8thold)
	{
		if(currency_a < currency_b)
			direction = 0; //-- 0-buy; 1-sell; 9-nosignal;
		else
			direction = 1;

		outputLog("g8diff:" + g8diff);

		//-- open order if no order, open order if g8diff is bigger than last one and change orders traget.
		if(OrdersTotal()==0)
		{
			openOrder(direction, g8diff, magicnumber, stoploss);
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
					if(OrderMagicNumber() == magicnumber && OrderSymbol()==Symbol())
					{
						if(StrToDouble(OrderComment()) > oldG8Diff)
						{
							oldG8Diff = StrToDouble(OrderComment());
						}
					}
				}
			}

			if(oldG8Diff==0) //-- if current symbol have no order then open order
			{
				openOrder(direction, g8diff, magicnumber, stoploss);
			}
			else if(oldG8Diff > 0 && g8diff >= (oldG8Diff + 1))
			{
				openOrder(direction, g8diff, magicnumber, stoploss);
				//adjustOrderTP(); [redraw fibonacci]
			}
		}
	}

	//-- display the g8 diff
	Comment(g8diff);
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
void drawFibo(int _ordertype, int _ticket)
{
	string objName = "fibo_" + _ticket;
	datetime fiboDate[2];
	double fiboValue[2];

	//-- get second 
	fiboDate[1] = iTime(Symbol(), 0, 0);
	if(_ordertype==0)
		fiboValue[1] = iLow(Symbol(), 0, 0);
	else
		fiboValue[1] = iHigh(Symbol(), 0, 0);

	if(ObjectFind(objName)<0)
	{
		ObjectCreate(objName, OBJ_FIBO, 0, fiboDate[0], fiboValue[0], fiboDate[1], fiboValue[1]);
		WindowRedraw();
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

//-- open order func **not complete**
int openOrder(int _direction, string _comment, int _magicnumber, int _stoploss)
{
	color _arrow;
	double _lots, _price, _sl, _tp;

	_lots = calcuLots();

	if(_direction == 0)
	{
		_arrow = Blue;
		_price = Ask;
		_sl = _price - _stoploss * Point;
	}
	else
	{
		_arrow = Red;
		_price = Bid;
		_sl = _price + _stoploss * Point;
	}

	// _tp = getPriceByFibo(_fiboName);

	int ordert = OrderSend(Symbol(), _direction, _lots, _price, 0, _sl, _tp, _comment, _magicnumber, 0, _arrow);

	return(ordert);
}

//-- update order take profit func **not complete**
void updateOrderTP(int _ticket, string _fiboName)
{
	// double _newtp = getPriceByFibo(_fiboName);

	OrderSelect(_ticket, SELECT_BY_TICKET);

	//OrderModify(_ticket, OrderOpenPrice(), OrderStopLoss(), _newtp, 0, Blue);
}

//-- get price by fibonacci object ** not complete**
double getPriceByFibo(string _fiboName)
{

}


//-- close order func
void closeOrder(int _ticket, int _percent=100)
{
	color closeArrow;
	double closePrice, closeLots;
	if (OrderSelect(_ticket, SELECT_BY_TICKET, MODE_TRADES))
	{
		if(OrderType()==OP_BUY)
		{
			closeArrow = Blue;
			closePrice = Ask;
		}
		else
		{
			closeArrow = Red;
			closePrice = Bid;
		}

		if(_percent==100)
			closeLots = OrderLots();
		else
			closeLots = NormalizeDouble(OrderLots() * (_percent / 100), 2);

		OrderClose(_ticket, closeLots, closePrice, 1, closeArrow);
	}
}

//-- use to get fibonacci price
double getFiboPrice(double _leftprice, double _rightprice, int _level)
{
	if(_leftprice<=0 || _rightprice<=0)
		return(0);

	double fiboPrice, fiboPercent;

	if(_level==0)
		fiboPercent = 0.000;
	else if(_level==1)
		fiboPercent = 0.236;
	else if(_level==2)
		fiboPercent = 0.382;
	else if(_level==3)
		fiboPercent = 0.500;
	else if(_level==4)
		fiboPercent = 0.618;
	else if(_level==5)
		fiboPercent = 0.764;
	else if(_level==6)
		fiboPercent = 1.000;

	if(_leftprice > _rightprice)
		fiboPrice = _rightprice + ((_leftprice - _rightprice) * fiboPercent);
	else
		fiboPrice = _rightprice - ((_rightprice - _leftprice) * fiboPercent);

	return(fiboPrice);
}