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
 * v0.0.8  [dev] 2012-11-01 finished getKLineNum() func;
 * v0.0.9  [dev] 2012-11-02 add money management swith;
 * v0.1.0  [dev] 2012-11-02 add adjustFibo() func use to adjust fibonacci retracement object;
 * v0.1.1  [dev] 2012-11-02 add draw finbonacci line switch.
 * v0.1.2  [dev] 2012-11-03 add adjustTP() func uset to adjust order takeprofit;
 * v0.1.3  [dev] 2012-11-06 check margin level when open order;
 * v0.1.4  [dev] 2012-11-06 add broker digit check in init() func;
 */

//-- property info
#property copyright "Copyright ? 2012 Nerrsoft.com"
#property link 		"http://nerrsoft.com"

//-- extern var
extern string 	indicatorparam = "--------trade param--------";
extern double 	lots = 0.01;
extern int 		stoploss = 30;
extern double 	g8thold = 3;
extern int 		historykline = 30;
extern int 		magicnumber = 911;
extern bool		moneymanagment = true;
extern bool		drawfiboline = true;
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

	if(Digits % 2 == 1)
		stoploss *= 10;

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

	double currency_a = iCustom(NULL, -1, "G8_USD", false, index_a, 0);
	double currency_b = iCustom(NULL, -1, "G8_USD", false, index_b, 0);

	double g8diff = MathAbs(currency_a - currency_b);

	//--
	if(g8diff >= g8thold)
	{
		int orderticket;

		if(currency_a < currency_b)
			direction = 0; //-- 0-buy; 1-sell; 9-nosignal;
		else
			direction = 1;

		//outputLog("g8diff:" + g8diff);

		//-- open order if no order, open order if g8diff is bigger than last one and change orders traget.
		if(OrdersTotal()==0)
		{
			orderticket = openOrder(direction, g8diff, magicnumber, stoploss);
			if(drawfiboline == true) drawFibo(direction, orderticket);
		}
		else
		{
			double oldG8Diff = 0;
			int firstorderticket = 0;
			for(int i = 0; i < OrdersTotal(); i++)
			{
				if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
				{
					// todo - no select order
				}
				else
				{
					if(OrderMagicNumber() == magicnumber && OrderSymbol()==Symbol() && OrderType()==direction)
					{
						//-- find the last order G8 diff indicator
						if(StrToDouble(OrderComment()) > oldG8Diff)
							oldG8Diff = StrToDouble(OrderComment());

						//-- find the first order ticket
						if(firstorderticket == 0)
							firstorderticket = OrderTicket();
						else if(firstorderticket < OrderTicket())
							firstorderticket = OrderTicket();
					}
				}
			}

			//-- open order
			if(oldG8Diff==0) //-- if current symbol have no order then open new order
			{
				orderticket = openOrder(direction, g8diff, magicnumber, stoploss);
				if(drawfiboline == true) drawFibo(direction, orderticket);
			}
			else if(oldG8Diff > 0 && g8diff >= (oldG8Diff + 1)) //-- if have order and current g8diff > the old max one than open order
			{
				openOrder(direction, g8diff, magicnumber, stoploss);
			}

			//-- adjust order tp and fibonacci retracement 
			if(oldG8Diff > 0 && g8diff > oldG8Diff)
			{
				if(drawfiboline == true)
				{
					adjustFibo(direction, firstorderticket);
					adjustTP(direction, firstorderticket);
				}
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

	lots*=5;

	return(lots);
}


//-- check margin safe or not
bool checkMarginSafe(int _direction, double _lots)
{
	double freemargin = AccountFreeMarginCheck(Symbol(), _direction, _lots);

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

int getKLineNum(int _ordertype)
{
	
	double p;
	int k;

	for(int i = 1; i<=historykline; i++)
	{
		if(_ordertype==0)
		{
			if(i==1)
				p = High[1];
			else
			{
				if(High[i] > p)
				{
					p = High[i];
					k = i;
				}
			}
		}
		else if(_ordertype==1)
		{
			if(i==1)
				p = Low[1];
			else
			{
				if(Low[i] < p)
				{
					p = Low[i];
					k = i;
				}
			}
		}
	}
	return(k);
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

	if(moneymanagment==true)
		_lots = calcuLots();
	else
		_lots = lots;

	//-- check margin level
	if(checkMarginSafe(_direction, _lots)==false)
	{
		outputLog("Out of safe margin level!");
		return (0);
	}

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
void adjustTP(int _direction, int _ticket)
{
	double takeprofit, leftprice, rightprice;

	leftprice = ObjectGet("fibo_" + _ticket, 1);
	rightprice = ObjectGet("fibo_" + _ticket, 3);

	takeprofit = getFiboPrice(leftprice, rightprice, 2);

	for(int i = 0; i < OrdersTotal(); i++)
	{
		if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
		{
			// todo - no select order
		}
		else
		{
			if(OrderMagicNumber() == magicnumber && OrderSymbol()==Symbol() && OrderType()==_direction)
			{
				OrderModify(_ticket, OrderOpenPrice(), OrderStopLoss(), takeprofit, 0);
			}
		}
	}
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

/*
	func about fibonacci retracement
	draw, adjust, delete
*/
//-- draw a fibonacci
void drawFibo(int _direction, int _ticket)
{
	if(_ticket <= 0)
		return(0);

	string objName = "fibo_" + _ticket;
	datetime fiboDate[2];
	double fiboValue[2];

	//-- get first param k line number
	int k = getKLineNum(_direction);

	fiboDate[0] = Time[k];
	fiboDate[1] = Time[0];
	if(_direction==0)
	{
		fiboValue[0] = High[k];
		fiboValue[1] = Low[0];
	}
	else
	{
		fiboValue[0] = Low[k];
		fiboValue[1] = High[0];
	}

	if(ObjectFind(objName)<0)
	{
		ObjectCreate(objName, OBJ_FIBO, 0, fiboDate[0], fiboValue[0], fiboDate[1], fiboValue[1]);
		WindowRedraw();
	}
}

//-- adjust a fibonacci
void adjustFibo(int _direction, int _ticket)
{
	double p;

	if(_direction==0)
		p = Low[0];
	else
		p = High[0];

	string objName = "fibo_" + _ticket;

	if(ObjectFind(objName)==0)
		ObjectMove(objName, 1, Time[0], p);
}

//-- delete a fibonacci
bool delFibo(int _ticket)
{
	return(ObjectDelete("fibo_" + _ticket));
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