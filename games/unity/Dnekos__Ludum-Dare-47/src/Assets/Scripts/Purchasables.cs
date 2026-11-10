using UnityEngine;
using System.Data;
using Mono.Data.Sqlite;
using System.IO;

public class Purchasable
{
    public string Name;
    protected int ID;

    public int quantity = 0; // how many cows
    public int used = 0; // how many are not working as a hand or being worked on
    public double price; // how much for a cow
    public float growth_rate; // how much price changes

    public int first_upgrade_index;
    public int applied_upgrades = 0;

    public int Available { get { return quantity - used; } }

    public bool Purchase()
    {
        if ((price * 100) <= PlayerManager.Inst.money * 100)
        {
            PlayerManager.Inst.money = PlayerManager.Inst.money - (price * 100 * 0.01);
            price *= growth_rate;
            price = Mathf.Round((float)price * 100) / 100;
            quantity++;
            return true;
        }
        return false;
    }
}

public class Worker : Purchasable
{
    public float time_multiplier;

    public Worker()
    {
        ID = 7;
        quantity = 0;
        used = 0;

        // Create database
        string connection = "URI=file:" + Application.dataPath + "/" + "LD47.db";
        Debug.Log(connection);
        // Open connection
        IDbConnection dbcon = new SqliteConnection(connection);
        dbcon.Open();

        // Read and print all values in table
        IDbCommand cmnd_read = dbcon.CreateCommand();
        IDataReader reader;
        string query = "SELECT * FROM Purchasables WHERE ID = 7";
        cmnd_read.CommandText = query;
        reader = cmnd_read.ExecuteReader();

        while (reader.Read())
        {
            ID = int.Parse(reader[0].ToString());
            Name = reader[1].ToString();
            price = double.Parse(reader[2].ToString());//new Currency(float.Parse(reader[2].ToString()),0);
            growth_rate = float.Parse(reader[3].ToString());
            time_multiplier = float.Parse(reader[6].ToString());
            first_upgrade_index = int.Parse(reader[8].ToString());
        }

        // Close connection
        dbcon.Close();
    }
}

public class Workspace : Purchasable
{
    public int milkcost;
    public bool making_milk = false;

    public double value; // how much they produce per click
    public float recharge_time; // how long till can be clicked again

    public string actionphrase;

    public Workspace(int ID)
    {
        if (ID == 1)
            quantity = 1;
        else
            quantity = 0;
        used = 0;

        // Create database
        string connection = "URI=file:" + Application.dataPath + "/" + "LD47.db";
        //Debug.Log(connection);
        // Open connection
        IDbConnection dbcon = new SqliteConnection(connection);
        dbcon.Open();
        
        // Read and print all values in table
        IDbCommand cmnd_read = dbcon.CreateCommand();
        IDataReader reader;
        string query = "SELECT * FROM Purchasables WHERE ID = " + ID;
        Debug.Log(query);
        cmnd_read.CommandText = query;
        reader = cmnd_read.ExecuteReader();

        while (reader.Read())
        {
            ID = int.Parse(reader[0].ToString());
            Name = reader[1].ToString();
            price = double.Parse(reader[2].ToString());//new Currency(float.Parse(reader[2].ToString()), 0);
            growth_rate = float.Parse(reader[3].ToString());
            value = double.Parse(reader[4].ToString());//new Currency(float.Parse(reader[4].ToString()), 0);
            actionphrase = reader[5].ToString();
            recharge_time = float.Parse(reader[6].ToString());
            milkcost = int.Parse(reader[7].ToString());
            first_upgrade_index = int.Parse(reader[8].ToString());
            Debug.Log(reader[0].ToString());
        }

        // Close connection
        dbcon.Close();
    }
}

public enum Up_Catagory
{
    Value,
    Time,
    Price,
    MilkCost,
    WinGame
}

public struct Upgrade
{
    public int ID;
    public string Name;
    public int PurchasableIndex;
    public Up_Catagory Catagory;
    public float multiplier;
    public int Unlock1, Unlock2;

    public Upgrade(int index)
    {
        if (index == -1)
        {
            ID = index;
            Name = "Rocket Ship";
            PurchasableIndex = -1;
            Catagory = Up_Catagory.WinGame;
            multiplier = 0;
            Unlock1 = 0;
            Unlock2 = 0;
            return;
        }


        // defaults
        ID = index;
        Name = "";
        PurchasableIndex = 0;
        Catagory = (Up_Catagory)0;
        multiplier = 0; 
        Unlock1 = 0;
        Unlock2 = 0;

        // Create database
        string connection = "URI=file:" + Application.dataPath + "/" + "LD47.db";
        //Debug.Log(connection);
        // Open connection
        IDbConnection dbcon = new SqliteConnection(connection);
        dbcon.Open();

        // Read and print all values in table
        IDbCommand cmnd_read = dbcon.CreateCommand();
        IDataReader reader;
        string query = "SELECT * FROM Upgrades WHERE ID = " + ID;
        //Debug.Log(query);
        cmnd_read.CommandText = query;
        reader = cmnd_read.ExecuteReader();

        while (reader.Read())
        {
            Name = reader[1].ToString();
            PurchasableIndex = int.Parse(reader[2].ToString());
            Catagory = (Up_Catagory) int.Parse(reader[3].ToString());
            multiplier = float.Parse(reader[4].ToString());
            Unlock1 = int.Parse(reader[5].ToString());
            Unlock2 = int.Parse(reader[6].ToString());
        }

        // Close connection
        dbcon.Close();
    }
}

public struct Research
{
    public int ID;
    public string Name;
    public int Rank;

    public Research(int index)
    {
        ID = index;
        Rank = 0;
        Name = "UPGRADE_NAME";

        switch(index)
        {
            case 0:
                Name = "Cow Portal";
                break;
            case 1:
                Name = "Goat Portal";
                break;
            case 2:
                Name = "Cream Portal";
                break;
            case 3:
                Name = "Cheese Portal";
                break;
            case 4:
                Name = "Ice Cream Portal";
                break;
            case 5:
                Name = "Yogurt Portal";
                break;
            case 6:
                Name = "Farmhand Portal";
                break;
            case 7:
                Name = "Deep Pockets";
                break;
            case 8:
                Name = "Reverse Expiration Date";
                break;
            case 9:
                Name = "Flux Capacitor";
                break;
        }
    }
}