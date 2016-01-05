
import java.io.*;
import java.nio.charset.Charset;
import java.util.ArrayList;

public class Tester {

    InputStream fis;
    InputStreamReader isr;
    BufferedReader br;
    ArrayList<TestObject> tests = new ArrayList<>(),
                          results = new ArrayList<>();
    int testsCounter = 0, resultsCounter = 0;
    ArrayList<String> output = new ArrayList<>();

    public Tester() {
        String line;

        try {
            fis = new FileInputStream("test_input");
            isr = new InputStreamReader(fis, Charset.forName("UTF-8"));
            br = new BufferedReader(isr);

            while ((line = br.readLine()) != null) {
                String parts[] = line.split(" ");
                String parts2[];
                if (parts[1].equals("TEST")) {
                    testsCounter++;
                    TestObject test = new TestObject(testsCounter);
                    tests.add(test);
                    do {
                        line = br.readLine();
                        parts2 = line.split(" ");
                        if (parts2[0].equals("TIME:")) test.time = Integer.parseInt(parts2[1]);
                        else test.results.add(Integer.parseInt(parts2[1]));
                    }
                    while (parts2[0].equals(">"));
                }
                else if (parts[1].charAt(0) == '(') {
                    resultsCounter++;
                    TestObject result = new TestObject(resultsCounter);
                    results.add(result);
                    result.time = Integer.parseInt(parts[1].substring(1, parts[1].length()-1));
                    while ((line = br.readLine()).contains(">")) {
                        parts2 = line.split(" ");
                        result.results.add(Integer.parseInt(parts2[1]));
                    }
                }
            }
        }
        catch (Exception e) {
            System.out.println("Java_Tester - Error while reading from file");
        }
        finally {
            try {
                fis.close();
                br.close();
                isr.close();
            }
            catch (IOException e) {
                e.printStackTrace();
            }
        }


		boolean ok = true;
        if (results.size() != tests.size()) p("Different sizes");
        for (int i = 0; i < results.size(); i++) {
            TestObject test = tests.get(i);
            TestObject result = results.get(i);
            boolean printed = false;
            for (int j = 0; j < result.results.size(); j++) {
                int a = test.results.get(j);
                int b = result.results.get(j);
                if (a != b) {
                    String out = "";
                    if (!printed) {
                        output.add("TEST " + i);
                        printed = true;
                    }
					ok = false;
                    output.add("IS: "+a+" | SHOULD BE: "+b);
                }
            }
            if (!printed) {
                if (test.time < result.time) output.add("TEST "+i+"-> BETTER TIME: IS: "+test.time+" | WAS: "+result.time);
                else if (test.time > result.time) output.add("TEST "+i+"-> WORSE TIME: IS: "+test.time+" | WAS: "+result.time);
            }
        }
		
		if (ok) p("TEST OK");

        for (String s : output) p(s);


    }

    void p(String s) {
        System.out.println(s);
    }


    public static void main(String args[]) {
        new Tester();
    }
}
