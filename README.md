# WSN
computer network homework
## How to run gui.java
>cd fcg<br>
 cd gui<br>
 javac gui.java<br>
 java gui

below are some commands that provides
+ "start": begin to collect message to 'result.txt'
+ "stop": stop collect message
+ "gui": show the gui
+ "exit": quit the program

```java
if (command.equals("start")) {
    thread.start(); //begin to collect message to 'result.txt'
}
else if (command.equals("stop")) {
    this.loopFLag = false; //stop collect message
}
else if (command.equals("exit")) {
    break;
}
else if (command.equals("gui")) {
    this.initGui();
}

```
