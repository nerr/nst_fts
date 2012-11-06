# About

Nerr Smart Trader - Fibonacci Retracement Trading System 

This idea comes from [http://www.forexfactory.com/showthread.php?t=212301](http://www.forexfactory.com/showthread.php?t=212301)
Thanks wjqblog for share his trading model.

## extern variable explain ##
<table>
	<tr>
		<td>*name*</td>
		<td>*default*</td>
		<td>*desc*</td>
	</tr>
	<tr>
		<td>_baselots_</td>
		<td>0.01</td>
		<td>open order use this value as lots if "moneymanagment" is false </td>
	</tr>
	<tr>
		<td>_stoploss_</td>
		<td>30</td>
		<td>stop loss pips</td>
	</tr>
	<tr>
		<td>_g8thold_</td>
		<td>4</td>
		<td>open order tigger value of g8diff (it show on chart ttop left corner)</td>
	</tr>
	<tr>
		<td>_historykline_</td>
		<td>30</td>
		<td>use to find the highest or lowest price for the fibonacci retracement</td>
	</tr>
	<tr>
		<td>_magicnumber_</td>
		<td>911</td>
		<td>use to tag the order opened by this EA</td>
	</tr>
	<tr>
		<td>_moneymanagment_</td>
		<td>true</td>
		<td>use auto calculate lots or not</td>
	</tr>
</table>


# License

	Copyright (c) 2012 Nerrsoft.com

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.