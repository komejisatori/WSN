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

import java.io.IOException;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class WsnDataBase extends JFrame implements MessageListener, ActionListener {

  private MoteIF moteIF;
  
  JPanel contentPane;
  JTextArea textAreaOutput;
  JButton beginButton;
  JButton endButton;
  JButton clearButton;
  JButton newTimerButton;
  boolean receiveFLag = true;
  JTextField textField1; 
  File file;
  public FileOutputStream out;
  int systemStatus = 0;
  int count1 = 0;
  int count2 = 0;
  public WsnDataBase(MoteIF moteIF) {
    this.moteIF = moteIF;
    this.moteIF.registerListener(new WsnDataBaseMsg(), this);
    this.commandLoop();
  }

  public void sendPackets(int newTimePeriod) {
    WsnDataBaseMsg payload = new WsnDataBaseMsg();
    try {
      payload.set_type(1);
      payload.set_newTimerPeriod(newTimePeriod);
      moteIF.send(0, payload);
    }
    catch (IOException exception) {
      System.err.println("Exception thrown when sending packets. Exiting.");
      System.err.println(exception);
    }
  }

  public void messageReceived(int to, Message message) {
    WsnDataBaseMsg msg = (WsnDataBaseMsg)message;
    String str = "";
    str += Integer.toString(msg.get_nodeId()) + ' ';
    str += Integer.toString(msg.get_temperature()) + ' ';
    str += Integer.toString(msg.get_humidity()) + ' ';
    str += Integer.toString(msg.get_illumination()) + ' ';
    str += Integer.toString((int)msg.get_collectTime()) + ' ';
    str += Integer.toString((int)msg.get_sequenceNumber()) + '\n';
    if(this.systemStatus == 1){
      if(msg.get_nodeId() == 2 && this.count1 != msg.get_sequenceNumber() - 1 && this.count1 != msg.get_sequenceNumber()){
        this.addStr("node2 warning\n");
      }
      if(msg.get_nodeId() == 3 && this.count2 != msg.get_sequenceNumber() - 1 && this.count2 != msg.get_sequenceNumber()){
        this.addStr("node3 warning\n");
      }
    }
    if(msg.get_nodeId() == 2)
      this.count1 = msg.get_sequenceNumber();
    if(msg.get_nodeId() == 3)
      this.count2 = msg.get_sequenceNumber();
    //if((this.systemStatus == 1 && (msg.get_sequenceNumber() - count != 1)))
    //{
    //  this.addStr("warning\n");
    //}
    //  count = msg.get_sequenceNumber();
    /*
    if (this.receiveFLag == true) {
      byte bt[];
      bt = str.getBytes();
      try {
        out.write(bt, 0, bt.length);
      } catch (IOException e) {  
        // TODO Auto-generated catch block  
        e.printStackTrace();  
      } 
    }*/

    if (this.systemStatus == 1) {
      addStr(str);
    }
  }
  
  private static void usage() {
    System.err.println("usage: TestSerial [-comm <source>]");
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
    newTimerButton = new JButton("调整计时器");
    textField1 = new JTextField();
    beginButton.setSize(20, 10);
    endButton.setSize(20, 10);
    clearButton.setSize(20, 10);
    newTimerButton.setSize(20, 10);
    textField1.setSize(20,10);
    textField1.setColumns(10);
    beginButton.addActionListener(this);
    endButton.addActionListener(this);
    clearButton.addActionListener(this);
    newTimerButton.addActionListener(this);
    pane1.add(beginButton);
    pane1.add(endButton);  
    pane1.add(clearButton);
    pane1.add(newTimerButton);
    pane1.add(textField1);

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
    this.systemStatus = 1;
    this.addStr("begin\n");
  }

  public void endCollect () {
    if (this.systemStatus == 0) {
      return;
    }
    this.systemStatus = 0;
    this.addStr("end\n");
  }

  public void setTimePeriod() {
    String str = textField1.getText();
    int newTime = Integer.parseInt(str);
    sendPackets(newTime);
  }

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
    else if (newTimerButton == e.getSource()) {
      this.setTimePeriod();
    }
  }

  public void commandLoop () {
    Scanner in = new Scanner(System.in);
    String command = null;
    do {
        System.out.println("Please Enter Command :");
        command = in.nextLine();
        if (command.equals("start")) {
          file = new File("result.txt");
          try {  
            file.createNewFile(); // �����ļ�  
          } catch (IOException e) {  
            e.printStackTrace();  
          }
          try {  
            out = new FileOutputStream(file); 
          } catch (FileNotFoundException e) {  
            e.printStackTrace();  
          } 
          this.receiveFLag = true;
        }
        else if (command.equals("stop")) {
          this.receiveFLag = false;
          try {
            this.out.close();
          } catch (IOException e) {
            e.printStackTrace();
          }
        }
        else if (command.equals("exit")) {
          this.receiveFLag = false;
          try {
            this.out.close();
          } catch (IOException e) {
            e.printStackTrace();
          }
          break;
        }
        else if (command.equals("gui")) {
          this.initGui();
        }
    } while (true);
  }

  public static void main(String[] args) throws Exception {
    String source = "serial@/dev/ttyUSB0:telos";
    /*
    if (args.length == 2) {
      if (!args[0].equals("-comm")) {
	usage();
	System.exit(1);
      }
      source = args[1];
    }
    else if (args.length != 0) {
      usage();
      System.exit(1);
    }
    */
    PhoenixSource phoenix;
    phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);

    MoteIF mif = new MoteIF(phoenix);
    WsnDataBase serial = new WsnDataBase(mif);

  }


}
