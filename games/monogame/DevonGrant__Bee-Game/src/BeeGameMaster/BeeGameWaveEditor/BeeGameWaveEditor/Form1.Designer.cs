namespace BeeGameWaveEditor
{
    partial class Form1
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.menuStrip1 = new System.Windows.Forms.MenuStrip();
            this.lToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.enemyBox = new System.Windows.Forms.TextBox();
            this.EnemyLabel = new System.Windows.Forms.Label();
            this.loadButton = new System.Windows.Forms.Button();
            this.saveButton = new System.Windows.Forms.Button();
            this.enemySelector = new System.Windows.Forms.ComboBox();
            this.selectedEnemyLabel = new System.Windows.Forms.Label();
            this.xPosBox = new System.Windows.Forms.TextBox();
            this.yPosBox = new System.Windows.Forms.TextBox();
            this.xPosLabel = new System.Windows.Forms.Label();
            this.yPosLabel = new System.Windows.Forms.Label();
            this.waveLabel = new System.Windows.Forms.Label();
            this.waveFileBox = new System.Windows.Forms.TextBox();
            this.outputBox = new System.Windows.Forms.ListBox();
            this.outputLabel = new System.Windows.Forms.Label();
            this.colorBox = new System.Windows.Forms.TextBox();
            this.textureBox = new System.Windows.Forms.ComboBox();
            this.textureLabel = new System.Windows.Forms.Label();
            this.healthBox = new System.Windows.Forms.TextBox();
            this.healthLabel = new System.Windows.Forms.Label();
            this.ColorLabel = new System.Windows.Forms.Label();
            this.openFileDialog1 = new System.Windows.Forms.OpenFileDialog();
            this.saveFileDialog1 = new System.Windows.Forms.SaveFileDialog();
            this.newEnemyButton = new System.Windows.Forms.Button();
            this.newEnemyNameBox = new System.Windows.Forms.TextBox();
            this.newEnemyLabel = new System.Windows.Forms.Label();
            this.panel1 = new System.Windows.Forms.Panel();
            this.menuStrip1.SuspendLayout();
            this.panel1.SuspendLayout();
            this.SuspendLayout();
            // 
            // menuStrip1
            // 
            this.menuStrip1.ImageScalingSize = new System.Drawing.Size(32, 32);
            this.menuStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.lToolStripMenuItem});
            this.menuStrip1.Location = new System.Drawing.Point(0, 0);
            this.menuStrip1.Name = "menuStrip1";
            this.menuStrip1.Size = new System.Drawing.Size(638, 40);
            this.menuStrip1.TabIndex = 0;
            this.menuStrip1.Text = "menuStrip1";
            // 
            // lToolStripMenuItem
            // 
            this.lToolStripMenuItem.Name = "lToolStripMenuItem";
            this.lToolStripMenuItem.Size = new System.Drawing.Size(154, 36);
            this.lToolStripMenuItem.Text = "Wave Editor";
            // 
            // enemyBox
            // 
            this.enemyBox.Location = new System.Drawing.Point(18, 277);
            this.enemyBox.Margin = new System.Windows.Forms.Padding(4);
            this.enemyBox.Name = "enemyBox";
            this.enemyBox.Size = new System.Drawing.Size(238, 31);
            this.enemyBox.TabIndex = 1;
            this.enemyBox.TextChanged += new System.EventHandler(this.applyValue);
            // 
            // EnemyLabel
            // 
            this.EnemyLabel.AutoSize = true;
            this.EnemyLabel.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.EnemyLabel.Location = new System.Drawing.Point(6, 204);
            this.EnemyLabel.Margin = new System.Windows.Forms.Padding(4, 0, 4, 0);
            this.EnemyLabel.Name = "EnemyLabel";
            this.EnemyLabel.Size = new System.Drawing.Size(134, 26);
            this.EnemyLabel.TabIndex = 2;
            this.EnemyLabel.Text = "Enemy Type";
            // 
            // loadButton
            // 
            this.loadButton.Location = new System.Drawing.Point(180, 825);
            this.loadButton.Margin = new System.Windows.Forms.Padding(6);
            this.loadButton.Name = "loadButton";
            this.loadButton.Size = new System.Drawing.Size(150, 44);
            this.loadButton.TabIndex = 3;
            this.loadButton.Text = "Load";
            this.loadButton.UseVisualStyleBackColor = true;
            this.loadButton.Click += new System.EventHandler(this.loadButton_Click);
            // 
            // saveButton
            // 
            this.saveButton.Location = new System.Drawing.Point(18, 825);
            this.saveButton.Margin = new System.Windows.Forms.Padding(6);
            this.saveButton.Name = "saveButton";
            this.saveButton.Size = new System.Drawing.Size(150, 44);
            this.saveButton.TabIndex = 4;
            this.saveButton.Text = "Save";
            this.saveButton.UseVisualStyleBackColor = true;
            this.saveButton.Click += new System.EventHandler(this.saveButton_Click);
            // 
            // enemySelector
            // 
            this.enemySelector.BackColor = System.Drawing.SystemColors.Window;
            this.enemySelector.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.enemySelector.FormattingEnabled = true;
            this.enemySelector.Location = new System.Drawing.Point(18, 198);
            this.enemySelector.Margin = new System.Windows.Forms.Padding(6);
            this.enemySelector.MaxDropDownItems = 12;
            this.enemySelector.Name = "enemySelector";
            this.enemySelector.Size = new System.Drawing.Size(238, 33);
            this.enemySelector.TabIndex = 6;
            this.enemySelector.SelectionChangeCommitted += new System.EventHandler(this.enemySelector_SelectionChangeCommitted);
            // 
            // selectedEnemyLabel
            // 
            this.selectedEnemyLabel.AutoSize = true;
            this.selectedEnemyLabel.Location = new System.Drawing.Point(6, 124);
            this.selectedEnemyLabel.Margin = new System.Windows.Forms.Padding(6, 0, 6, 0);
            this.selectedEnemyLabel.Name = "selectedEnemyLabel";
            this.selectedEnemyLabel.Size = new System.Drawing.Size(78, 25);
            this.selectedEnemyLabel.TabIndex = 7;
            this.selectedEnemyLabel.Text = "Enemy";
            // 
            // xPosBox
            // 
            this.xPosBox.Location = new System.Drawing.Point(294, 277);
            this.xPosBox.Margin = new System.Windows.Forms.Padding(6);
            this.xPosBox.Name = "xPosBox";
            this.xPosBox.Size = new System.Drawing.Size(76, 31);
            this.xPosBox.TabIndex = 8;
            this.xPosBox.TextChanged += new System.EventHandler(this.applyValue);
            // 
            // yPosBox
            // 
            this.yPosBox.Location = new System.Drawing.Point(386, 277);
            this.yPosBox.Margin = new System.Windows.Forms.Padding(6);
            this.yPosBox.Name = "yPosBox";
            this.yPosBox.Size = new System.Drawing.Size(76, 31);
            this.yPosBox.TabIndex = 9;
            this.yPosBox.TextChanged += new System.EventHandler(this.applyValue);
            // 
            // xPosLabel
            // 
            this.xPosLabel.AutoSize = true;
            this.xPosLabel.Location = new System.Drawing.Point(288, 246);
            this.xPosLabel.Margin = new System.Windows.Forms.Padding(6, 0, 6, 0);
            this.xPosLabel.Name = "xPosLabel";
            this.xPosLabel.Size = new System.Drawing.Size(63, 25);
            this.xPosLabel.TabIndex = 10;
            this.xPosLabel.Text = "XPos";
            // 
            // yPosLabel
            // 
            this.yPosLabel.AutoSize = true;
            this.yPosLabel.Location = new System.Drawing.Point(380, 246);
            this.yPosLabel.Margin = new System.Windows.Forms.Padding(6, 0, 6, 0);
            this.yPosLabel.Name = "yPosLabel";
            this.yPosLabel.Size = new System.Drawing.Size(64, 25);
            this.yPosLabel.TabIndex = 11;
            this.yPosLabel.Text = "YPos";
            // 
            // waveLabel
            // 
            this.waveLabel.AutoSize = true;
            this.waveLabel.Location = new System.Drawing.Point(6, 11);
            this.waveLabel.Margin = new System.Windows.Forms.Padding(6, 0, 6, 0);
            this.waveLabel.Name = "waveLabel";
            this.waveLabel.Size = new System.Drawing.Size(108, 25);
            this.waveLabel.TabIndex = 14;
            this.waveLabel.Text = "Wave File";
            // 
            // waveFileBox
            // 
            this.waveFileBox.Location = new System.Drawing.Point(18, 85);
            this.waveFileBox.Margin = new System.Windows.Forms.Padding(6);
            this.waveFileBox.Name = "waveFileBox";
            this.waveFileBox.ReadOnly = true;
            this.waveFileBox.Size = new System.Drawing.Size(222, 31);
            this.waveFileBox.TabIndex = 15;
            // 
            // outputBox
            // 
            this.outputBox.FormattingEnabled = true;
            this.outputBox.ItemHeight = 25;
            this.outputBox.Items.AddRange(new object[] {
            " "});
            this.outputBox.Location = new System.Drawing.Point(18, 581);
            this.outputBox.Margin = new System.Windows.Forms.Padding(6);
            this.outputBox.Name = "outputBox";
            this.outputBox.Size = new System.Drawing.Size(554, 229);
            this.outputBox.TabIndex = 18;
            // 
            // outputLabel
            // 
            this.outputLabel.AutoSize = true;
            this.outputLabel.Location = new System.Drawing.Point(12, 550);
            this.outputLabel.Margin = new System.Windows.Forms.Padding(6, 0, 6, 0);
            this.outputLabel.Name = "outputLabel";
            this.outputLabel.Size = new System.Drawing.Size(118, 25);
            this.outputLabel.TabIndex = 19;
            this.outputLabel.Text = "Output Log";
            // 
            // colorBox
            // 
            this.colorBox.Location = new System.Drawing.Point(18, 351);
            this.colorBox.Margin = new System.Windows.Forms.Padding(4);
            this.colorBox.Name = "colorBox";
            this.colorBox.Size = new System.Drawing.Size(238, 31);
            this.colorBox.TabIndex = 20;
            this.colorBox.TextChanged += new System.EventHandler(this.applyValue);
            // 
            // textureBox
            // 
            this.textureBox.BackColor = System.Drawing.SystemColors.Window;
            this.textureBox.FormattingEnabled = true;
            this.textureBox.Items.AddRange(new object[] {
            "enemyTexture"});
            this.textureBox.Location = new System.Drawing.Point(294, 198);
            this.textureBox.Margin = new System.Windows.Forms.Padding(6);
            this.textureBox.MaxDropDownItems = 12;
            this.textureBox.Name = "textureBox";
            this.textureBox.Size = new System.Drawing.Size(278, 33);
            this.textureBox.TabIndex = 21;
            this.textureBox.TextChanged += new System.EventHandler(this.applyValue);
            // 
            // textureLabel
            // 
            this.textureLabel.AutoSize = true;
            this.textureLabel.Location = new System.Drawing.Point(288, 167);
            this.textureLabel.Margin = new System.Windows.Forms.Padding(6, 0, 6, 0);
            this.textureLabel.Name = "textureLabel";
            this.textureLabel.Size = new System.Drawing.Size(85, 25);
            this.textureLabel.TabIndex = 22;
            this.textureLabel.Text = "Texture";
            // 
            // healthBox
            // 
            this.healthBox.Location = new System.Drawing.Point(478, 277);
            this.healthBox.Margin = new System.Windows.Forms.Padding(6);
            this.healthBox.Name = "healthBox";
            this.healthBox.Size = new System.Drawing.Size(76, 31);
            this.healthBox.TabIndex = 23;
            this.healthBox.TextChanged += new System.EventHandler(this.applyValue);
            // 
            // healthLabel
            // 
            this.healthLabel.AutoSize = true;
            this.healthLabel.Location = new System.Drawing.Point(472, 246);
            this.healthLabel.Margin = new System.Windows.Forms.Padding(6, 0, 6, 0);
            this.healthLabel.Name = "healthLabel";
            this.healthLabel.Size = new System.Drawing.Size(74, 25);
            this.healthLabel.TabIndex = 24;
            this.healthLabel.Text = "Health";
            // 
            // ColorLabel
            // 
            this.ColorLabel.AutoSize = true;
            this.ColorLabel.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.ColorLabel.Location = new System.Drawing.Point(6, 278);
            this.ColorLabel.Margin = new System.Windows.Forms.Padding(4, 0, 4, 0);
            this.ColorLabel.Name = "ColorLabel";
            this.ColorLabel.Size = new System.Drawing.Size(64, 26);
            this.ColorLabel.TabIndex = 25;
            this.ColorLabel.Text = "Color";
            // 
            // openFileDialog1
            // 
            this.openFileDialog1.FileOk += new System.ComponentModel.CancelEventHandler(this.openFileDialog1_FileOk);
            // 
            // saveFileDialog1
            // 
            this.saveFileDialog1.FileOk += new System.ComponentModel.CancelEventHandler(this.saveFileDialog1_FileOk);
            // 
            // newEnemyButton
            // 
            this.newEnemyButton.Location = new System.Drawing.Point(263, 501);
            this.newEnemyButton.Name = "newEnemyButton";
            this.newEnemyButton.Size = new System.Drawing.Size(199, 38);
            this.newEnemyButton.TabIndex = 26;
            this.newEnemyButton.Text = "Add New Enemy";
            this.newEnemyButton.UseVisualStyleBackColor = true;
            this.newEnemyButton.Click += new System.EventHandler(this.newEnemyButton_Click);
            // 
            // newEnemyNameBox
            // 
            this.newEnemyNameBox.Location = new System.Drawing.Point(18, 505);
            this.newEnemyNameBox.Margin = new System.Windows.Forms.Padding(4);
            this.newEnemyNameBox.Name = "newEnemyNameBox";
            this.newEnemyNameBox.Size = new System.Drawing.Size(238, 31);
            this.newEnemyNameBox.TabIndex = 27;
            // 
            // newEnemyLabel
            // 
            this.newEnemyLabel.AutoSize = true;
            this.newEnemyLabel.Location = new System.Drawing.Point(13, 476);
            this.newEnemyLabel.Margin = new System.Windows.Forms.Padding(6, 0, 6, 0);
            this.newEnemyLabel.Name = "newEnemyLabel";
            this.newEnemyLabel.Size = new System.Drawing.Size(188, 25);
            this.newEnemyLabel.TabIndex = 28;
            this.newEnemyLabel.Text = "New Enemy Name";
            // 
            // panel1
            // 
            this.panel1.Controls.Add(this.waveLabel);
            this.panel1.Controls.Add(this.selectedEnemyLabel);
            this.panel1.Controls.Add(this.EnemyLabel);
            this.panel1.Controls.Add(this.ColorLabel);
            this.panel1.Location = new System.Drawing.Point(12, 43);
            this.panel1.Name = "panel1";
            this.panel1.Size = new System.Drawing.Size(581, 379);
            this.panel1.TabIndex = 29;
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(12F, 25F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(638, 892);
            this.Controls.Add(this.newEnemyLabel);
            this.Controls.Add(this.newEnemyNameBox);
            this.Controls.Add(this.newEnemyButton);
            this.Controls.Add(this.healthLabel);
            this.Controls.Add(this.healthBox);
            this.Controls.Add(this.textureLabel);
            this.Controls.Add(this.textureBox);
            this.Controls.Add(this.colorBox);
            this.Controls.Add(this.outputLabel);
            this.Controls.Add(this.outputBox);
            this.Controls.Add(this.waveFileBox);
            this.Controls.Add(this.yPosLabel);
            this.Controls.Add(this.xPosLabel);
            this.Controls.Add(this.yPosBox);
            this.Controls.Add(this.xPosBox);
            this.Controls.Add(this.enemySelector);
            this.Controls.Add(this.saveButton);
            this.Controls.Add(this.loadButton);
            this.Controls.Add(this.enemyBox);
            this.Controls.Add(this.menuStrip1);
            this.Controls.Add(this.panel1);
            this.MainMenuStrip = this.menuStrip1;
            this.Margin = new System.Windows.Forms.Padding(4);
            this.Name = "Form1";
            this.Text = "Wave Editor";
            this.menuStrip1.ResumeLayout(false);
            this.menuStrip1.PerformLayout();
            this.panel1.ResumeLayout(false);
            this.panel1.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.MenuStrip menuStrip1;
        private System.Windows.Forms.ToolStripMenuItem lToolStripMenuItem;
        private System.Windows.Forms.TextBox enemyBox;
        private System.Windows.Forms.Label EnemyLabel;
        private System.Windows.Forms.Button loadButton;
        private System.Windows.Forms.Button saveButton;
        private System.Windows.Forms.ComboBox enemySelector;
        private System.Windows.Forms.Label selectedEnemyLabel;
        private System.Windows.Forms.TextBox xPosBox;
        private System.Windows.Forms.TextBox yPosBox;
        private System.Windows.Forms.Label xPosLabel;
        private System.Windows.Forms.Label yPosLabel;
        private System.Windows.Forms.Label waveLabel;
        private System.Windows.Forms.TextBox waveFileBox;
        private System.Windows.Forms.ListBox outputBox;
        private System.Windows.Forms.Label outputLabel;
        private System.Windows.Forms.TextBox colorBox;
        private System.Windows.Forms.ComboBox textureBox;
        private System.Windows.Forms.Label textureLabel;
        private System.Windows.Forms.TextBox healthBox;
        private System.Windows.Forms.Label healthLabel;
        private System.Windows.Forms.Label ColorLabel;
        private System.Windows.Forms.OpenFileDialog openFileDialog1;
        private System.Windows.Forms.SaveFileDialog saveFileDialog1;
        private System.Windows.Forms.Button newEnemyButton;
        private System.Windows.Forms.TextBox newEnemyNameBox;
        private System.Windows.Forms.Label newEnemyLabel;
        private System.Windows.Forms.Panel panel1;
    }
}

