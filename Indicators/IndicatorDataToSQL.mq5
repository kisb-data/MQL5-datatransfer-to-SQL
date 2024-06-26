//+------------------------------------------------------------------+
//|                     Copyright 2024, kisb-data                    |
//|                     kisbalazs.data@gmail.com                     |
//+------------------------------------------------------------------+

/*
   This is an example of use my SQL libary, the libary is uniqe as you see in the SQLite_access example
   There are lot another possibilities to include, 
   but my porpose was to export data to SQL database and read it later from python.
   So, joining and different asking methode are not included from the MQL side.
*/

#property indicator_chart_window
#property indicator_plots   0

int ma_handle=-1;
string table_MA = "MA";

//---insert libary
#include <kisb_data\\SQL\\SYS_SQLite_access.mqh>

//---create class
CSQLite * SQL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

//--- create class
   SQL = new CSQLite();

//--- open/create database
   SQL.OpenCreateDatabase("IndicatorData", "MA_Example");

//--- table data
   string cols[2] = {"datetime", "MA_Data"};
   string col_typs[2] = {"TEXT", "REAL"};

//--- check if table exist, if not create it
   if(!SQL.TableExist(table_MA))
     {
      SQL.CreateTable(table_MA, cols, col_typs);
     }

//--- Define the parameters for the iCustom call
   string indicatorName = "Examples\\Custom Moving Average";
   int maPeriod = 14;
   int maShift = 0;
   int maMethod = MODE_SMA;
   int maPrice = PRICE_CLOSE;

//--- Initialize the Moving Average indicator using iCustom
   ma_handle = iCustom(_Symbol, PERIOD_CURRENT, indicatorName, maPeriod, maShift, maMethod, maPrice);

//--- close database
   SQL.CloseDatabase();

//--- return if can not create indicator data  
   if(ma_handle == INVALID_HANDLE)
     {
      Print("Failed to initialize the Moving Average indicator with iCustom");
      return(INIT_FAILED);
     }

//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- delete class
   delete SQL;

  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---

//--- Check if a new bar has been formed
   if(rates_total <= prev_calculated)
      return(prev_calculated);

//--- open/create database
   SQL.OpenCreateDatabase("IndicatorData", "MA_Example");
   
//--- get last row id
   string ret[];
   SQL.GetLastRowData(table_MA, ret);

//--- set bars to the last time data 
   int bars=0;
   if(ArraySize(ret)==0)
      bars = Bars(_Symbol, PERIOD_CURRENT);
   else
      bars = iBarShift(_Symbol, PERIOD_CURRENT, StringToTime(ret[1]));
  
//return if no new data to export
   if(bars==0)
     {
      SQL.CloseDatabase();
      return(rates_total);
     }

//--- Retrieve the last values of the indicator
   double ma_value[];
   if(CopyBuffer(ma_handle, 0, 0, bars, ma_value) <= 0)
     {
      Print("Failed to retrieve data");
      SQL.CloseDatabase();
      return(rates_total);
     }

//--- Retrieve the last value of the time
   datetime time_value[];
   if(CopyTime(_Symbol,  PERIOD_CURRENT, 0, bars, time_value) <= 0)
     {
      Print("Failed to retrieve data");
      return(prev_calculated);
     }

//--- insert data into the database
   string values="";
   for(int i=0; i<bars; i++)
   {
      values+="('"+TimeToString(time_value[i]) +"','"+DoubleToString(ma_value[i])+"')";
      if(i<bars-1)
         values+=",";
      else
         values+=";";
   }
     
   SQL.InsertData(table_MA, "'datetime','MA_Data'", values);

   Print("New candle data included.");
   
//--- close database
   SQL.CloseDatabase();

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
