
//+------------------------------------------------------------------+
//|                                                                  |
//|                     Copyright 2024, kisb-data                    |
//|                     kisbalazs.data@gmail.com                     |
//|                                                                  |
//|                                                                  |
//|  This code is free software: you can redistribute it and/or      |
//|  modify it under the terms of the GNU General Public License as  |
//|  published by the Free Software Foundation, either version 3 of  |
//|  the License, or (at your option) any later version.             |
//|                                                                  |
//|  This code is distributed in the hope that it will be useful,    |
//|  but WITHOUT ANY WARRANTY; without even the implied warranty of  |
//|  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the    |
//|  GNU General Public License for more details.                    |
//|                                                                  |
//|  You should have received a copy of the GNU General Public       |
//|  License along with this code. If not, see                       |
//|  <http://www.gnu.org/licenses/>.                                 |
//|                                                                  |
//|  Additional terms:                                               |
//|  You may not use this software in products that are sold.        |
//|  Redistribution and use in source and binary forms, with or      |
//|  without modification, are permitted provided that the           |
//|  following conditions are met:                                   |
//|                                                                  |
//|  1. Redistributions of source code must retain the above         |
//|     copyright notice, this list of conditions and the following  |
//|     disclaimer.                                                  |
//|                                                                  |
//|  2. Redistributions in binary form must reproduce the above      |
//|     copyright notice, this list of conditions and the following  |
//|     disclaimer in the documentation and/or other materials       |
//|     provided with the distribution.                              |
//|                                                                  |
//|  3. Neither the name of the copyright holder nor the names of    |
//|     its contributors may be used to endorse or promote products  |
//|     derived from this software without specific prior written    |
//|     permission.                                                  |
//|                                                                  |
//|  4. Products that include this software may not be sold.         |
//|                                                                  |
//+------------------------------------------------------------------+

/*
   this libary is for working with database in MQL5
*/

#property strict


/**********************************************************************************************************************
   CColors class
**********************************************************************************************************************/
class CSQLite
  {

private:

   string            m_folder;
   string            m_filename;
   int               m_db_handle;
   string            m_last_error;
   bool              m_print;

public:
   void              CSQLite(bool print=true) {m_print=print;};
   void             ~CSQLite() {};

   bool              OpenCreateDatabase(string folder, string filename);
   void              CloseDatabase() {DatabaseClose(m_db_handle); Print("=======>"+"Database closed ("+m_filename+")");};

   bool              TableExist(string table) {return(DatabaseTableExists(m_db_handle, table));};
   bool              TableInfo(string table);
   bool              CreateTable(string name, string &cols[], string &col_typs[]);
   bool              DropTable(string table);
   bool              IsLocked();
   void              PrintTable(string table_name);

   bool              InsertColumn(string table_name, string column_name, string column_type);
   bool              RemoveColumn(string table_name, string column_name);

   bool              InsertData(string table_name, string cols, string data);
   bool              RemoveRowByID(string table_name, int id);
   bool              ModifyDataBy(string table_name, string column_name, string value, int id);
   bool              GetLastRow(string table_name);
   bool              GetLastRowData(string table_name, string &data[]);
   string            LastError() {return(m_last_error);};
   void              LastErrorReset() {m_last_error="";};
  };



/**********************************************************************************************************************
   open/create
**********************************************************************************************************************/
bool CSQLite::OpenCreateDatabase(string folder, string filename)
  {

   //folder mean subfolder, everithig will be exported to the common folder+subfolder
   m_folder=folder;
   m_filename=filename;
   m_last_error="";

   //open or create database
   m_db_handle=DatabaseOpen(folder+"\\"+filename+".sqlite", DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
   if(m_db_handle < 0)
     {
      m_last_error="Failed to open database, error: "+DoubleToString(GetLastError(),0);
      if(m_print) Print("=======>"+m_last_error);
      return(false);
     }

   if(m_print) Print("=======>"+"Opened database successfully ("+filename+")");

   return(true);
  };

/**********************************************************************************************************************
   get table info
**********************************************************************************************************************/
bool CSQLite::TableInfo(string table)
  {
   //print table info
   if(DatabasePrint(m_db_handle, "PRAGMA TABLE_INFO("+table+")", 0)<0)
     {
      m_last_error="Unable to read table info, error: "+DoubleToString(GetLastError(),0);
      if(m_print) Print("=======>"+m_last_error);
      return(false);
     }

   return(true);
  }

/**********************************************************************************************************************
   create table
**********************************************************************************************************************/
bool CSQLite::CreateTable(string table, string &cols[], string &col_typs[])
  {
   //array size need match
   if(ArraySize(cols) != ArraySize(col_typs))
     {
      m_last_error="Error: The number of column names and types do not match.";
      if(m_print) Print("=======>"+m_last_error);
      return(false);
     }

   //sql command
   string req="CREATE TABLE IF NOT EXISTS "+table+"(id INTEGER PRIMARY KEY AUTOINCREMENT,";

   for(int i=0; i<ArraySize(cols); i++)
     {
      req+=" "+cols[i]+" "+col_typs[i];
      if(i<ArraySize(cols)-1)
         req+=",";
     }
   req=req+");";

   //execute command
   if(!DatabaseExecute(m_db_handle, req))
     {
      m_last_error="Table: "+ table+ " create table failed with code, error: "+DoubleToString(GetLastError(),0);
      if(m_print) Print("=======>"+m_last_error);
      return(false);
     }

   if(m_print) Print("=======>"+"Table created ("+table+")");

   return(true);
  }

/**********************************************************************************************************************
   drop table
**********************************************************************************************************************/
bool CSQLite::DropTable(string table)
  {
   // if table exist, drop
   if(DatabaseTableExists(m_db_handle, table))
     {
      if(!DatabaseExecute(m_db_handle, "DROP TABLE "+table))
        {
         m_last_error="Failed to drop table "+table+" with code, error: "+DoubleToString(GetLastError(),0);
         if(m_print) Print("=======>"+m_last_error);
         return(false);
        }
     }
     
   return(true);
  }

/**********************************************************************************************************************
   check if database or table is locked
**********************************************************************************************************************/
bool CSQLite::IsLocked()
  {

   int err=GetLastError();
   if(err==5605 /*ERR_DATABASE_BUSY*/ || err==5606 /*ERR_DATABASE_LOCKED*/)
      return(true);

   return(false);
  };

/**********************************************************************************************************************
   print whole table
**********************************************************************************************************************/
void CSQLite::PrintTable(string table_name)
  {

   //keep in mind you can not print empty table, if the table is empty you can only print the table info
   if(DatabasePrint(m_db_handle, "SELECT * FROM "+table_name+";", 0)) ;
   else
     {
      m_last_error="Failed to print table. error: "+DoubleToString(GetLastError(),0);
      if(m_print) Print("=======>"+m_last_error);
     }
  }

/**********************************************************************************************************************
   insert column in table
**********************************************************************************************************************/
bool CSQLite::InsertColumn(string table_name, string column_name, string column_type)
  {
   //sql command
   string sqlCommand = "ALTER TABLE "+table_name+" ADD COLUMN " +column_name+" "+ column_type+";";
 
   //execute command
   if(DatabaseExecute(m_db_handle, sqlCommand))
     {
      if(m_print) Print("=======>"+"Column added successfully.");
      return(true);
     }
   else
     {
      m_last_error="Failed to add the column. error: "+DoubleToString(GetLastError(),0);
      if(m_print) Print("=======>"+m_last_error);
     }

   return(false);
  }

/**********************************************************************************************************************
   remove column from table
**********************************************************************************************************************/
bool CSQLite::RemoveColumn(string table_name, string column_name)
  {
   //sql command
   string sqlCommand = "ALTER TABLE "+table_name+" DROP COLUMN " +column_name+";";

   //execute command
   if(DatabaseExecute(m_db_handle, sqlCommand))
     {
      if(m_print) Print("=======>"+"Column added successfully.");
      return(true);
     }
   else
     {
      m_last_error="Failed to remove the column. error: "+DoubleToString(GetLastError(),0);
      if(m_print) Print("=======>"+m_last_error);
     }

   return(false);
  }

/**********************************************************************************************************************
   insert data in table
**********************************************************************************************************************/
bool CSQLite::InsertData(string table_name, string cols, string values)
  {
   //values should be one or more rows ('val1','val2',...), ('val1','val2',...);
   DatabaseTransactionBegin(m_db_handle);
   bool failed=false;

   //sql command
   string sqlCommand = "INSERT INTO "+table_name+" ("+cols+") VALUES "+values+";";

   //execute command
   if(!DatabaseExecute(m_db_handle, sqlCommand))
     {
      m_last_error="Failed to insert data, error: "+DoubleToString(GetLastError(),0);
      if(m_print) Print("=======>"+m_last_error);
      failed=true;
     }

   //check for transaction execution errors
   if(failed)
     {
      //--- roll back all transactions and unlock the database
      DatabaseTransactionRollback(m_db_handle);
      return(false);
     }
     
   //all transactions have been performed successfully - record changes and unlock the database
   DatabaseTransactionCommit(m_db_handle);

   return(true);
  };

/**********************************************************************************************************************
   insert column in table
**********************************************************************************************************************/
bool CSQLite::RemoveRowByID(string table_name, int id)
  {
   
   //sql command
   string sqlCommand = "DELETE FROM "+table_name+" WHERE id="+DoubleToString(id,0)+";";

   //execute command
   if(DatabaseExecute(m_db_handle, sqlCommand))
     {
      if(m_print) Print("=======>"+"Row added successfully.");
      return(true);
     }
   else
     {
      m_last_error="Failed to remove row. error: "+DoubleToString(GetLastError(),0);
      if(m_print) Print("=======>"+m_last_error);
     }

   return(false);
  };

/**********************************************************************************************************************
   modify data
**********************************************************************************************************************/
bool CSQLite::ModifyDataBy(string table_name, string column_name, string value, int uniq_id)
  {
   
   //sql command
   string sqlCommand = "UPDATE "+table_name+" SET "+column_name+" = "+value+" WHERE id="+DoubleToString(uniq_id,0)+";";

   //execute command
   if(DatabaseExecute(m_db_handle, sqlCommand))
     {
      if(m_print) Print("=======>"+"Data updated successfully.");
      return(true);
     }
   else
     {
      m_last_error="Failed to modify data. error: "+DoubleToString(GetLastError(),0);
      if(m_print) Print("=======>"+m_last_error);
     }

   return(false);
  }

/**********************************************************************************************************************
   get last row data
**********************************************************************************************************************/
bool CSQLite::GetLastRow(string table_name)
  {

   //sql command
   string sqlCommand = "SELECT * FROM "+table_name+" ORDER BY rowid DESC LIMIT 1;";

   //execute command
   if(DatabasePrint(m_db_handle, sqlCommand, 0))
     {
      return(true);
     }
   else
     {
      m_last_error="Failed to add the column."+DoubleToString(GetLastError(),0);
      if(m_print) Print("=======>"+m_last_error);
     }

   return(false);
  }

/**********************************************************************************************************************
   get last row id
**********************************************************************************************************************/
bool CSQLite::GetLastRowData(string table_name, string &data[])
  {

   //sql command
   string sqlCommand = "SELECT * FROM "+table_name+" ORDER BY rowid DESC LIMIT 1;";

   //prepare database
   int request=DatabasePrepare(m_db_handle, sqlCommand);
   if(request==INVALID_HANDLE)
     {
      m_last_error="Create request failed with code, error: "+DoubleToString(GetLastError(),0);
      if(m_print) Print("=======>"+m_last_error);
      DatabaseClose(m_db_handle);
      return(false);
     }

   //set return array size
   ArrayResize(data, DatabaseColumnsCount(request));
   
   //read data due to column type (not all types are included)
   if(DatabaseRead(request))
      for(int i=0; i<DatabaseColumnsCount(request); i++)
      {
         if(DatabaseColumnType(request, i)==DATABASE_FIELD_TYPE_INTEGER)
         {
            int val;
            if(!DatabaseColumnInteger(request, i, val))  // Assuming you want the data from the first column (index 0)
              {
               m_last_error="Read data from request failed with code, error: "+DoubleToString(GetLastError(),0);
               if(m_print) Print("=======>"+m_last_error);
               DatabaseClose(m_db_handle);
               return(false);
              }
            data[i]=DoubleToString(val,0);
         }
         if(DatabaseColumnType(request, i)==DATABASE_FIELD_TYPE_FLOAT)
         {
            double val;
            if(!DatabaseColumnDouble(request, i, val))  // Assuming you want the data from the first column (index 0)
              {
               m_last_error="Read data from request failed with, error: "+DoubleToString(GetLastError(),0);
               if(m_print) Print("=======>"+m_last_error);
               DatabaseClose(m_db_handle);
               return(false);
              }
            data[i]=DoubleToString(val);
         }
         
         if(DatabaseColumnType(request, i)==DATABASE_FIELD_TYPE_TEXT)
         {
            string val;
            if(!DatabaseColumnText(request, i, val))  // Assuming you want the data from the first column (index 0)
              {
               m_last_error="Read data from request failed with code, error: "+DoubleToString(GetLastError(),0);
               if(m_print) Print("=======>"+m_last_error);
               DatabaseClose(m_db_handle);
               return(false);
              }
            data[i]=val;
         }
      }

   DatabaseFinalize(request);

   return(true);
  }
//+------------------------------------------------------------------+
