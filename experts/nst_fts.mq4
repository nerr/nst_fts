/* Nerr SmartTrader - Multi Broker Trader - Slave
 * 
 * @History
 * v0.0.0  [dev] 2012-09-03 init.
 */

//-- property info
#property copyright "Copyright ? 2012 Nerrsoft.com"
#property link 		"http://nerrsoft.com"

//-- extern var
extern string 	indicatorparam = "--------trade param--------";
extern double 	lots = 1;
extern int 		stoploss = 20;
extern double 	g8thold = 3;
extern int 		historykline = 15;
extern string 	maceindicatorparam = "--------indicator param of macd--------";
extern int 		macdfastema = 12;
extern int 		macdslowema = 26;
extern int 		macesma = 9;
extern string 	kdindicatorparam = "--------indicator param of kd--------";
extern int 		kperiod = 5;
extern int 		dperiod = 3;
extern int 		kdslowing = 3;
extern string 	g8indicatorparam = "--------indicator param of g8 usd--------";


//-- init
int init()
{

}

//-- deinit
int deinit()
{
	return(0);
}

//-- start
int start()
{
	int tradesignal = getSingal();

	switch(tradesignal)
	{
		case 0:
			break;
		case 1:
			break;
		default:
			break;
	}
}

//--











/*
	return int value desc
	0 - buy singal
	1 - sell singal
	9 - no singal


*/
int getSingal()
{
	//double currency_a = iCustom(NULL, -1, "G8_USD_v1.1", );
	//double currency_b = iCustom(NULL, -1, "G8_USD_v1.1", );

	if((MathAbs(currency_a) + MathAbs(currency_b)) >= g8thold)
	{
		if(currency_b > current_a)
			return(0);
		else
			return(1);
	}
	else
	{
		return(9);
	}
}


//-- get lots by kd(Stochastic)
/*
	look you kd

	if kd>75. oversold you maybe use 1.5-2% risk
	if kd<75 not oversold you maybe use 0.5-1% risk

	like 500$ in the example.20 pips stop loss

	500*1%=5$/20pips=0.025 lots
*/
double getLots()
{
	double lots, rate;
	double kd = ;

	if(kd>0.75)
		rate = 1.75;
	else if(kd<0.75)
		rate = 0.75;

	lots = (AccountEquity() * rate) / 20;

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
	if(marginlevel>30) //-- safe margin level set to 3000%
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