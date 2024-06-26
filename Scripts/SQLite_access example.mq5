//+------------------------------------------------------------------+
//|                     Copyright 2024, kisb-data                    |
//|                     kisbalazs.data@gmail.com                     |
//+------------------------------------------------------------------+

//--- insert libary
#include <MTE Classes2\\SYS_SQLite_access.mqh>

//--- create class
CSQLite          * SQL;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//--- header
   Print("");
   Print("Start SQL example.");

//--- create class
   SQL = new CSQLite();

//--- create database
   SQL.OpenCreateDatabase("SQL_example", "example");

//--- table data
   string table = "Test";
   string cols[2] = {"Col1", "Col2"};
   string col_typs[2] = {"REAL", "REAL"};

//--- check if table exist
   if(SQL.TableExist(table))
     {
      Print("Delete exist table. ("+table+")");
      SQL.DropTable(table);
     }

//--- make a table
   Print("Create new table. ("+table+")");
   SQL.CreateTable(table, cols, col_typs);

//--- check if table exist
   Print("Chack if table exist. ("+table+")");
   if(!SQL.TableExist(table))
      Print("Table not exist. ("+table+")");
   else
      Print("Table exist. ("+table+")");

//--- check table info
   Print("Table info:");
   SQL.TableInfo(table);

//--- insert column
   SQL.InsertColumn(table, "Col3", "Text");

//--- check table info after insertion
   Print("Table info after new column:");
   SQL.TableInfo(table);

//--- insert single row data into table
   SQL.InsertData(table, "'Col1','Col2','Col3'", "('1','2','text');");
   SQL.InsertData(table, "'Col1','Col2','Col3'", "('3','4','text');");

//--- check table after inserting row
   Print("Print table after added columns:");
   SQL.PrintTable(table);

//--- remove first row
   SQL.RemoveRowByID(table, 1);

//--- check table after remove row
   Print("Print table after remove column:");
   SQL.PrintTable(table);

//--- modify data
   SQL.ModifyDataBy(table, "Col1", "100", 2);

//--- check table after remove row
   Print("Print table with modify data:");
   SQL.PrintTable(table);

//--- add data array
   string values;
   for(int i=0; i<5; i++)
   {
      values+="('"+DoubleToString(i,0)+"', '"+DoubleToString(i+1,0)+"', 'Number as text:"+DoubleToString(i+2,0)+"')";
      
      if(i<4)
         values+=",";
      else
         values+=";";
   }
   
   SQL.InsertData(table, "'Col1','Col2','Col3'", values);

//--- check table after remove row
   Print("Print table with added data array:");
   SQL.PrintTable(table);

//--- drop column
   SQL.RemoveColumn(table, "Col1");

//--- check table after drop column
   Print("Print table with modify data:");
   SQL.PrintTable(table);

//--- get last row data
   SQL.GetLastRow(table);

//--- last row data
   string ret[];
   SQL.GetLastRowData(table, ret);
   ArrayPrint(ret);

//--- close database
   SQL.CloseDatabase();

//--- delete class
   delete SQL;
  }

//+------------------------------------------------------------------+
