#include "functions.h"

vector<string> output;
vector<string> errors;
vector<Variable> variables;
struct Register registers[10];
unsigned long long int memoryIndex = 10;
unsigned long long int k = 0;
int error = 0;
int flag = 1;


unsigned long long int addIterator(string id) {
	Variable v;
	v.id = id;
	v.value = 0;
	v.stored = memoryIndex++;
	v.iterator = true;
	v.length = -1;
	variables.push_back(v);
	return memoryIndex - 1;
}


bool isIterator(string id) {
	for (auto i = variables.begin(); i != variables.end(); i++) {
		if (!i->id.compare(id) && i->iterator) return true;
	}
	return false;
}


void setIterator(unsigned long long int stored, Register reg) {
	Register reg_2 = getFreeRegister();
	setValueInRegister(stored - 10, reg_2.index);
	addOutput("STORE "+intToString(reg.index)+" "+intToString(reg_2.index));
	freeRegister(reg_2.index, true);
}


Register getIterator(unsigned long long int stored) {
	Register reg = getFreeRegister();
	Register reg_2 = getFreeRegister();
	setValueInRegister(stored - 10, reg.index);
	addOutput("LOAD "+intToString(reg_2.index)+" "+intToString(reg.index));
	return reg_2;
}


unsigned long long int storeTempVariable(unsigned long long int value) {
	unsigned long long int index = -1;
	if (value > 0) {
		for (auto i = variables.begin(); i != variables.end(); i++) {
			if (i->value == value && !i->id.compare("")) {
				index = i->stored;
				break;
			}
		}
	}
	if (index == -1) {} //Optimalize (exits that value in memory)
	else {}

	Register reg = getFreeRegister();
	Variable v;
	v.value = value;
	v.stored = memoryIndex;
	v.length = -1;
	v.id = "";
	variables.push_back(v);

	setValueInRegister(value, reg.index);
	Register reg2 = getFreeRegister();
	setValueInRegister(memoryIndex - 10, reg2.index);
	addOutput("STORE "+intToString(reg.index)+" "+intToString(reg2.index));
	freeRegister(reg2.index, false);
	registers[reg.index].positive = true;
	freeRegister(reg.index, false);
	return memoryIndex++;
}


bool checkIfInitialized(ParserVar p1, ParserVar p2) {
	//if ((p1.value == -1 && string(p1.name).compare("")) || (p2.value == -1 && string(p2.name).compare(""))) return true;
	//else return false;
	return false;
}


void storeVariable(ParserVar p1, ParserVar p2) {
	Variable v = getVariable(p1.name);
  if (p2.value == -1) v.value = 0;
	else v.value = p2.value;
	setVariable(v);
	if (p1.stored >= 10) {
		if (p1.index != -1) {	//Storing in array var(var1)
			Register reg1 = getFreeRegister();
			Register reg2 = getFreeRegister();
			setValueInRegister(p1.index - 10, reg1.index);
			addOutput("LOAD "+intToString(reg2.index)+" "+intToString(reg1.index));
			addOutput("RESET "+intToString(reg1.index));
			setValueInRegister(p1.stored - 10, reg1.index);
			addOutput("ADD "+intToString(reg1.index)+" "+intToString(reg2.index));
			freeRegister(reg2.index, true);
			reg2 = prepareRegister(p2);
			addOutput("STORE "+intToString(reg2.index)+" "+intToString(reg1.index));
			freeRegister(reg1.index, true);
		}
		else {
			Register reg = getFreeRegister();
			setValueInRegister(p1.stored - 10, reg.index);
			addOutput("STORE "+intToString(p2.stored)+" "+intToString(reg.index));
			freeRegister(reg.index, false);
		}
	}
	else {
		addOutput("STORE "+intToString(p2.stored)+" "+intToString(p1.stored));
		registers[p1.stored].positive = true;
		freeRegister(p1.stored, false);
	}
	freeRegister(p2.stored, true);
}


/*******************************  REGISTERS OPERATIONS BEGIN ***********************************/
Register getRegisterByIndex(int reg_index) {
	return registers[reg_index];
}


Register prepareRegister(ParserVar pv) {
	Register reg;
	if (pv.index != -1) {  //Array var(var2)
		reg = getFreeRegister();
		Register reg2 = getFreeRegister();
		setValueInRegister(pv.index - 10, reg2.index);
		addOutput("LOAD "+intToString(reg.index)+" "+intToString(reg2.index));
		addOutput("RESET "+intToString(reg2.index));
		setValueInRegister(pv.stored - 10, reg2.index);
		addOutput("ADD "+intToString(reg2.index)+" "+intToString(reg.index));
		addOutput("LOAD "+intToString(reg.index)+" "+intToString(reg2.index));
		freeRegister(reg2.index, true);
	}
	else if (pv.stored == -1) {  //Value
		print("ITS VALUE "+intToString(pv.value));
		reg = getFreeRegister();
		setValueInRegister(pv.value, reg.index);
	}
	else if (isRegister(pv.stored)) { //Value is already in register
		reg = getRegisterByIndex(pv.stored);
		if (!reg.iterator) return registers[pv.stored];
		else {
			Register reg_2 = getFreeRegister();
			addOutput("COPY "+intToString(reg_2.index)+" "+intToString(reg.index));
			setRegister(reg_2, true);
			return reg_2;
		}
	}
	else if (pv.stored >= 10) {
		reg = getFreeRegister();
		reg.id = pv.name;
		Register reg_2 = getFreeRegister();		//Register where stored is memory adress
		setValueInRegister(pv.stored - 10, reg_2.index);
		addOutput("LOAD "+intToString(reg.index)+" "+intToString(reg_2.index));
		freeRegister(reg_2.index, false);
	}
	reg.positive = true;
	return reg;
}


int setValueInRegister(unsigned long long int value, unsigned long long int reg_index) {
	vector<string> commands;
	unsigned long long int a = value;
	if (value > 0) registers[reg_index].positive = true;
	while (a > 0) {
		if (a < value) commands.push_back("SHL "+intToString(reg_index));
		if (a % 2 == 1) commands.push_back("INC "+intToString(reg_index));
		a /= 2;
	}
	for (int i = commands.size()-1; i >= 0; i--) addOutput(commands[i]);
	return reg_index;
}


void resetAllRegisters(bool reset) {
	if (reset) {
		for (int i = 0; i < 10; i++) freeRegister(i, false);
	}
	else {
		for (int i = 0; i < 10; i++) {
 			if (registers[i].positive == true && !registers[i].iterator) {
				addOutput("RESET "+intToString(i));
			}
 		}
 	}
}


Register getFreeRegister() {
	for (int i = 0; i < 10; i++) {
		if (registers[i].isFree) {
			if (!registers[i].initialized || registers[i].positive) {
				addOutput("RESET "+intToString(i));
				registers[i].initialized = true;
				registers[i].positive = false;
			}
			registers[i].isFree = false;
			return registers[i];
		}
	}
	yyerror("All registers used");
}


void storeIterator(ParserVar p, Register reg) {
	Register reg_2 = getFreeRegister();
	setValueInRegister(p.stored - 10, reg_2.index);
	addOutput("STORE "+intToString(reg.index)+" "+intToString(reg_2.index));
	freeRegister(reg_2.index, true);
	registers[reg.index].iterator = false;
	freeRegister(reg.index, true);
}


void deleteIterator(ParserVar p) {
	Variable v;
	v.id = p.name;
	v.iterator = true;
	deleteVariable(v);
}


void freeRegister(int reg_index, bool reset) {
	if (!getRegisterByIndex(reg_index).iterator) {
		if (reset) addOutput("RESET "+intToString(reg_index));
		else {
			if (registers[reg_index].positive == true) addOutput("RESET "+intToString(reg_index));
		}
		registers[reg_index].positive = false;
		registers[reg_index].isFree = true;
		registers[reg_index].id = "";
	}
}


void setRegister(Register reg, bool positive) {
	reg.positive = positive;
	registers[reg.index] = reg;
}


bool isRegister(unsigned long long int stored) {
	if (stored < 10 && stored >= 0) return true;
	return false;
}


void initRegisters() {
	for (int i = 0; i < 10; i++) registers[i].index = i;
}
/********************************  REGISTERS OPERATIONS END **********************************/

/*********************************** OPTIMALIZATION BEGIN ************************************/
unsigned long long int quickAddition(ParserVar ps1, ParserVar ps2) {
	Register reg;
	int max = 10;
	if ((ps1.stored == ps2.stored && ps1.index == ps2.index) && ps1.stored != -1) {  //Situation a + a;
		reg = prepareRegister(ps1);
		addOutput("SHL "+intToString(reg.index));
	}
	else if (ps1.stored == ps2.stored && ps1.stored == -1) {  //Situation 3 + 4
		reg = getFreeRegister();
		setValueInRegister(ps1.value + ps2.value, reg.index);
	}
	else if (ps2.stored == -1 && (ps2.value != -1 && ps2.value < max)) { //Situation a + value less than 10
		reg = prepareRegister(ps1);
		for (int i = 0; i < ps2.value; i++) addOutput("INC "+intToString(reg.index));
	}
	else if (ps1.stored == -1 && (ps1.value != -1 && ps1.value < max)) { //Situation value + a less than 10
		reg = prepareRegister(ps2);
		for (int i = 0; i < ps1.value; i++) addOutput("INC "+intToString(reg.index));
	}
	else return -1;
	setRegister(reg, true);
	return reg.index;
}


unsigned long long int quickSubtraction(ParserVar ps1, ParserVar ps2) {
	Register reg;
	int max = 10;
	if ((ps1.stored == ps2.stored && ps1.index == ps2.index) && ps1.stored != -1) {  //Situation a - a;
		reg = getFreeRegister();
		return reg.index;
	}
	else if ((ps1.stored == -1 && ps2.stored == -1) && (ps1.value != -1 && ps2.value != -1)) {  //Situation 6 - 3
		reg = getFreeRegister();
		if (ps1.value <= ps2.value) return reg.index;
		setValueInRegister(ps1.value - ps2.value, reg.index);
	}
	else if (ps2.stored == -1 && (ps2.value != -1 && ps2.value < max)) {   //Situation a - 3 less than 10
		reg = prepareRegister(ps1);
		for (int i = 0; i < ps2.value; i++) addOutput("DEC "+intToString(reg.index));
	}
	else if (ps1.stored == -1 && (ps1.value != -1 && ps1.value < max)) {   //Situation a - 3 less than 10
		reg = prepareRegister(ps2);
		for (int i = 0; i < ps1.value; i++) addOutput("DEC "+intToString(reg.index));
	}
	else return -1;
	setRegister(reg, true);
	return reg.index;
}


unsigned long long int quickMultiplication(ParserVar ps1, ParserVar ps2) {
	if (ps1.value > 0 || ps2.value > 0) {
		int values[] = { 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192 };
		int ps1_value = -1, ps2_value = -1;
		for (int i = 0; i < sizeof(values)/sizeof(*values); i++) {
			if (ps1.value == values[i]) ps1_value = i;
			if (ps2.value == values[i]) ps2_value = i;
		}
		if (ps1_value > -1 && ps2_value > -1) {
			if (ps1_value < ps2_value) return quickOperationsPrinter("SHL", ps1_value, ps2, ps1);
			else return quickOperationsPrinter("SHL", ps2_value, ps1, ps2);
			return -1;
		}
		else if (ps1_value > -1) return quickOperationsPrinter("SHL", ps1_value, ps2, ps1);
		else if (ps2_value > -1) return quickOperationsPrinter("SHL", ps2_value, ps1, ps2);
	}
	return -1;
}


unsigned long long int quickOperationsPrinter(string operation, int number, ParserVar ps1, ParserVar ps2) {
	unsigned long long int stored;
	number++;
	if (!isRegister(ps1.stored)) stored = prepareRegister(ps1).index;
	else stored = ps1.stored;
	for (int i = 0; i < number; i++) addOutput(operation+" "+intToString(stored));
	return stored;
}

/************************************ OPTIMALIZATION END *************************************/
unsigned long long int getK() {  return k; }


bool isDeclared(string id, bool isArray) {
	if (isArray) {
		for (auto i = variables.begin(); i != variables.end(); i++) {
			if (!i->id.compare(id) && i->length != -1) return true;
		}
	}
	else {
		for (auto i = variables.begin(); i != variables.end(); i++) {
			if (!i->id.compare(id) && i->length == -1) return true;
		}
	}
	return false;
}


string intToString(unsigned long long int value) {
	stringstream stream;
	stream<<value;
	return stream.str();
}


void setVariable(Variable v) {
	for (auto i = variables.begin(); i != variables.end(); i++) {
		if ((!i->id.compare(v.id) && i->iterator == v.iterator) && i->length == v.length) *i = v;
	}
}


Variable getVariable(string id) {
	for (auto i = variables.begin(); i != variables.end(); i++) {
		if (!i->id.compare(id) && i->iterator) return *i;
	}
	for (auto i = variables.begin(); i != variables.end(); i++) {
		if (!i->id.compare(id)) return *i;
	}
}


void declareVariable(string id, unsigned long long length) {
	Variable v;
	v.id = id;
	v.stored = memoryIndex;
	v.length = length;
	v.value = -1;
	variables.push_back(v);
	if (length == -1) {
		print("[declared variable]: "+id+" | stored: "+intToString(memoryIndex));
		memoryIndex++;
	}
	else if (length > 0) {
		print("[declared array]: "+id+" | array length: "+intToString(length)+" | stored from: "+intToString(memoryIndex));
		memoryIndex += length;
	}
	else yyerror("Declaring array with 0 length");
}


void deleteVariable(Variable v) {
	int counter;
	for (auto i = variables.begin(); i != variables.end(); i++) {
		if (!i->id.compare(v.id) && i->iterator == v.iterator) break;
		counter++;
	}
	if (counter < variables.size()) variables.erase(variables.begin() + counter);
}


/************************************* DEBUGGING BEGIN ******************************************/
void setPrintFlag(int _flag) {	flag = _flag; }


void print(string text) {	if (flag) cout<<text<<"\n"; }


void printOutput() {
	if (error) {
		print("\nCompilation failed:");
		for (int i = 0; i < errors.size(); i++) print("Error - "+errors[i]);
	}
	else {
		ofstream myfile;
  	myfile.open ("output.mr");
		print("\nCompilation successfully finished..\n[OUTPUT]");
		for (int i = 0; i < output.size(); i++) {
	  	myfile<<output[i]<<endl;
			print(intToString(i)+": "+output[i]);
		}
		myfile.close();
	}
}


void printVariables() {
	int j = 0;
	if (flag) {
		print("VARIABLES:");
		for (auto i = variables.begin(); i != variables.end(); i++) {
			cout<<"i: "<<j<<" | id: "<<i->id<<" | value: "<<i->value<<" | length: "<<i->length<<" | stored: "<<i->stored<<endl;
		}
		for (int i = 0; i < 4; i++) {
			cout<<"i: "<<i<<" | isFree: "<<registers[i].isFree<<" | id: "<<registers[i].id<<" | positive: "<<registers[i].positive<<endl;
		}
	}
}
/******************************************** DEBUGGING END ******************************************/


void addOutput(string s) {	output.push_back(s);  	k++; }


void setOutput(int index, string s) {	output[index] += s; }


void yyerror(string s) {
	error = 1;
	errors.push_back(s);
	printOutput();
	exit(0);
}
