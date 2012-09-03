/* Nerr SmartTrader - Multi Broker Trader - Slave
 * 
 * @History
 * v0.0.0  [dev] 2012-09-03 init.
 */

//-- property info
#property copyright "Copyright ? 2012 Nerrsoft.com"
#property link 		"http://nerrsoft.com"

//-- extern var

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

}

//--


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