using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.IO;

namespace BeeGameWaveEditor
{
    public partial class Form1 : Form
    {
        Dictionary<string, string[]> enemies = new Dictionary<string, string[]>();
        string filepath = "..\\..\\waves";

        public Form1()
        {
            InitializeComponent();
        }

        private void loadButton_Click(object sender, EventArgs e)
        {

            openFileDialog1.InitialDirectory = "..\\waves";
            openFileDialog1.ShowDialog();
        }

        private void openFileDialog1_FileOk(object sender, CancelEventArgs e)
        {
            enemies.Clear();
            enemySelector.Items.Clear();
            string fileName = openFileDialog1.FileName;
            using (StreamReader reader = new StreamReader(fileName))
            {
                string line;
                
                while ((line = reader.ReadLine()) != null)
                {

                    try
                    {
                        //Store the line data
                        string[] lineData = line.Split(',');
                        enemies.Add(lineData[0], lineData);
                        enemySelector.Items.Add(lineData[0]);
                    }
                    catch (IOException)
                    {
                        outputBox.Items.Add($"Error while loading file.");
                        return;
                    }
                }
                outputBox.Items.Add($"{openFileDialog1.SafeFileName} loaded successfully.");
                waveFileBox.Text = openFileDialog1.SafeFileName;
            }
        }

        private void saveButton_Click(object sender, EventArgs e)
        {
            saveFileDialog1.InitialDirectory = "";
            saveFileDialog1.ShowDialog();
        }

        private void saveFileDialog1_FileOk(object sender, CancelEventArgs e)
        {
            string fileName = saveFileDialog1.FileName;

            using(StreamWriter writer = new StreamWriter(fileName))
            {
                try
                {
                    foreach(KeyValuePair<string, string[]> enemy in enemies)
                    {
                        writer.WriteLine(
                            $"{enemy.Value[0]}," +
                            $"{enemy.Value[1]}," +
                            $"{enemy.Value[2]}," +
                            $"{enemy.Value[3]}," +
                            $"{enemy.Value[4]}," +
                            $"{enemy.Value[5]}," +
                            $"{enemy.Value[6]}");
                    }
                    outputBox.Items.Add($"{saveFileDialog1.FileName} saved successfully.");

                }
                catch (IOException)
                {
                    outputBox.Items.Add($"Error while saving file.");
                }
            }
        }

        private void enemySelector_SelectionChangeCommitted(object sender, EventArgs e)
        {            
            string[] outputValue;
            bool valueCheck = enemies.TryGetValue(enemySelector.SelectedItem.ToString(), out outputValue);
            if(valueCheck == true)
            {
                enemyBox.Text = outputValue[1];
                textureBox.Text = outputValue[2];
                xPosBox.Text = outputValue[3];
                yPosBox.Text = outputValue[4];
                colorBox.Text = outputValue[5];
                healthBox.Text = outputValue[6];
            }
        }

        private void applyValue(object sender, EventArgs e)
        {
            string[] outputValue;
            bool valueCheck = enemies.TryGetValue(enemySelector.SelectedItem.ToString(), out outputValue);

            if (valueCheck == true)
            {
                if (sender == enemyBox)
                {
                    enemies[enemySelector.SelectedItem.ToString()][1] = enemyBox.Text;
                }
                else if (sender == textureBox)
                {
                    enemies[enemySelector.SelectedItem.ToString()][2] = textureBox.Text;
                }
                else if (sender == xPosBox)
                {
                    enemies[enemySelector.SelectedItem.ToString()][3] = xPosBox.Text;
                }
                else if (sender == yPosBox)
                {
                    enemies[enemySelector.SelectedItem.ToString()][4] = yPosBox.Text;
                }
                else if (sender == colorBox)
                {
                    enemies[enemySelector.SelectedItem.ToString()][5] = colorBox.Text;
                }
                else if (sender == healthBox)
                {
                    enemies[enemySelector.SelectedItem.ToString()][6] = healthBox.Text;
                }
            }
        }

        private void newEnemyButton_Click(object sender, EventArgs e)
        {
            string enemyTemplate = $"{newEnemyNameBox.Text},base,bee,0,0,White,1";
            if (newEnemyNameBox.Text != "" && enemies.ContainsKey(newEnemyNameBox.Text) == false)
            {
                string[] newEnemy = enemyTemplate.Split(',');
                enemies.Add(newEnemy[0], newEnemy);
                enemySelector.Items.Add(newEnemy[0]);
                outputBox.Items.Add("Created a new enemy.");
            }
            else
            {
                outputBox.Items.Add("Cannot create an enemy with an empty or duplicate name.");
            }
        }
    }
}
