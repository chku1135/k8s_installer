import javax.management.MBeanServerConnection;
import javax.management.ObjectName;
import javax.management.remote.JMXConnector;
import javax.management.remote.JMXConnectorFactory;
import javax.management.remote.JMXServiceURL;
import java.io.FileWriter;
import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Timer;
import java.util.TimerTask;


public class kafka_usage_test {
    private static final String JMX_URL="service:jmx:rmi:///jndi/rmi://10.0.2.11:9090/jmxrmi";
    private static final String OBJECT_NAME="kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec";
    private static final String CSV_FILE="byte_in_per_sec.csv"; 

    public static void main(String[] args) throws Exception{
        JMXServiceURL url = new JMXServiceURL(JMX_URL);
        JMXConnector jmxc = JMXConnectorFactory.connect(url,null);
        MBeanServerConnection mbsc = jmxc.getMBeanServerConnection();
        ObjectName objName = new ObjectName(OBJECT_NAME);

        // CSV Header
        try(FileWriter writer = new FileWriter(CSV_FILE,true)) {
            writer.write("timestamp,count,meanRate,oneMinuteRate,fiveMinuteRate,fifteenMinuteRate\n");
        }

            Timeer timer = new Timer();
            timer.scheduleAtFixedRate(new TimerTask(){
                @Override
                public void run() {
                    try(FileWriter writer = new FileWriter(CSV_FILE, true)) {
                        long count = (Long) mbsc.getAttribute(objName, "Count");
                        double meanRate =  (Double) mbsc.getAttribute(objName, "MeanRate");
                        double oneMinuteRate = (Double) mbsc.getAttribute(objName, "OneMinuteRate");
                        double fiveMinuteRate = (Double) mbsc.getAttribute(objName, "FiveMinuteRate");
                        double fifteenMinuteRate = (Double) mbsc.getAttribute(objName, "FifteenMinuteRate");

                        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));

                        writer.write(String.formate("%s,%d,%.4f,%.4f,%.4f,%.4f\n",timestamp, count, meanRate, oneMinuteRate, fiveMinuteRate, fifteenMinuteRate));
                        
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            },0,60*1000);   // 1분 마다 실행
        
            // 프로그램 하루동안 실행
            Thread.sleep(24*60*60*1000);
            timer.canel();
            jmxc.close();
        
    }
}
