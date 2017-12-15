import java.io.File;  
import java.io.FileInputStream;  
import java.io.FileNotFoundException;  
import java.io.FileOutputStream;  
import java.io.IOException;  
import java.io.InputStreamReader;  
import java.util.Scanner;


public class testFile {

    public boolean loopFLag = true;
    public FileOutputStream out;

    public static void main (String[] args) {
        testFile test = new testFile();
        test.func();
    }

    public void func () {
        Scanner in = new Scanner(System.in);
        String command = null;
        MyThread thread = new MyThread();
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
}

