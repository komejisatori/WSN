import java.awt.GridLayout;

import javax.swing.JButton;
import javax.swing.JFrame;  
import javax.swing.JLabel;  
import javax.swing.JPanel;
import javax.swing.JRadioButtonMenuItem;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.JTextField;  
import javax.swing.border.EmptyBorder;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.TextArea;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import java.io.File;  
import java.io.FileInputStream;  
import java.io.FileNotFoundException;  
import java.io.FileOutputStream;  
import java.io.IOException;  
import java.io.InputStreamReader;  
import java.util.Scanner;

public class gui extends JFrame implements ActionListener{  
    JPanel contentPane;
    JTextArea textAreaOutput;
    JButton beginButton;
    JButton endButton;
    JButton clearButton;
    boolean loopFLag = true, loopFlag2 = true;
    public FileOutputStream out;
    public MyThread thread;
    public MyThread2 thread2;
    int systemStatus = 0;
    
    public gui(){  
        thread = new MyThread();
        this.commandLoop();
    }

    public void initGui () {
        contentPane = (JPanel)this.getContentPane();
        this.setTitle("gui");  
        this.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);  
        this.setBounds(100, 100, 800, 600);   
        contentPane.setBorder(new EmptyBorder(5,5,5,5));  
        contentPane.setLayout(new BorderLayout());  
        JPanel pane1=new JPanel();  
        contentPane.add(pane1, BorderLayout.NORTH);  
        JPanel pane2=new JPanel();  
        contentPane.add(pane2, BorderLayout.CENTER);  
        beginButton = new JButton("开始接收");
        endButton = new JButton("结束接收");
        clearButton = new JButton("清空");
        beginButton.setSize(20, 10);
        endButton.setSize(20, 10);
        clearButton.setSize(20, 10);
        beginButton.addActionListener(this);
        endButton.addActionListener(this);
        clearButton.addActionListener(this);
        pane1.add(beginButton);
        pane1.add(endButton);  
        pane1.add(clearButton);


        textAreaOutput = new JTextArea("", 30, 100);
        textAreaOutput.setSelectedTextColor(Color.RED);
        textAreaOutput.setLineWrap(true);
        textAreaOutput.setWrapStyleWord(true);
        textAreaOutput.setEditable(false);
        JScrollPane scrollPane = new JScrollPane(textAreaOutput);
        scrollPane.setBounds(0, 0, 10, 40);
        scrollPane.setVerticalScrollBarPolicy( JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
        pane2.add(scrollPane);
        this.setVisible(true);  
        this.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    }
    public void addStr (String str) {
        this.textAreaOutput.append(str);
    }
    
    public void clearStr () {
        this.textAreaOutput.setText("");
    }

    public void beginCollect () {
        if (this.systemStatus == 1) {
            return;
        }
        loopFlag2 = true;
        thread2 = new MyThread2();
        this.systemStatus = 1;
        this.addStr("begin\n");
        thread2.start();
    }

    public void endCollect () {
        if (this.systemStatus == 0) {
          return;
        }
        loopFlag2 = false;
        this.systemStatus = 0;
        this.addStr("end\n");
    }

    @Override
    public void actionPerformed(ActionEvent e) {
        if (clearButton == e.getSource()) {
          this.clearStr();
        }
        else if (beginButton == e.getSource()) {
          this.beginCollect();
        }
        else if (endButton == e.getSource()) {
          this.endCollect();
        }
        
    }

    public void commandLoop () {
        Scanner in = new Scanner(System.in);
        String command = null;
        do {
            System.out.println("Please Enter Command :");
            command = in.nextLine();
            if (command.equals("start")) {
                thread.start();
            }
            else if (command.equals("stop")) {
                this.loopFLag = false;
            }
            else if (command.equals("exit")) {
                break;
            }
            else if (command.equals("gui")) {
                this.initGui();
            }
        } while (true);
    }

    public class MyThread extends Thread
    {
        public void run () {
            File file = new File("result.txt");
            String str;
            byte bt[];
            try {  
                file.createNewFile(); // 创建文件  
            } catch (IOException e) {  
                // TODO Auto-generated catch block  
                e.printStackTrace();  
            }  
            try {  
                out = new FileOutputStream(file);  
                try {
                    int i = 0;
                    while (loopFLag) {
                        str = "hello" + Integer.toString(i++) + '\n';
                        bt = str.getBytes();
                        out.write(bt, 0, bt.length);
                        Thread.sleep(1000);
                    }
                    out.close();
                    // boolean success=true;  
                    // System.out.println("写入文件成功");  
                } catch (IOException e) {  
                    // TODO Auto-generated catch block  
                    e.printStackTrace();  
                } 
            } catch (FileNotFoundException|InterruptedException e) {  
                // TODO Auto-generated catch block  
                e.printStackTrace();  
            }  
        }
    }

    public class MyThread2 extends Thread
    {
        public void run () {
            int i = 0;
            String str;
            while (loopFlag2) {
                str = "hello" + Integer.toString(i++) + '\n';
                addStr(str);
                try{
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    public static void main(String[] args) {
        gui exampleGui = new gui();
    }
}  