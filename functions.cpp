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
	unsigned long long int index = 12;
	if (variables.size() > 0) {
		for (auto i = variables.begin(); i != variables.end(); i++) {
			if (i->stored < index)	index = i->stored;
		}
		if (index == 10) {
			v.stored = memoryIndex;
			index = memoryIndex++;
		}
		else v.stored = --index;
	}
	v.iterator = true;
	v.length = -1;
	variables.push_back(v);
	return index;
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


bool checkIfInitialized(ParserVar p1, ParserVar p2) {
	if ((p1.value == -1 && string(p1.name).compare("")) || (p2.value == -1 && string(p2.name).compare(""))) return true;
	else return false;
}


void storeVariable(ParserVar p1, ParserVar p2) {
	Variable v = getVariable(p1.name);
	v.value = 0;
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
		reg = getFreeRegister();
		setValueInRegister(pv.value, reg.index);
	}
	else if (isRegister(pv.stored)) return registers[pv.stored];	//Value is already in register
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
	yyerror("All registers in use");
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
		else if (registers[reg_index].positive == true) addOutput("RESET "+intToString(reg_index));
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
		int ps1_value = -1, ps2_value = -1;
		int i = 0, val;
		if (ps1.value != -1 && ps1.value != 0) {
			val = ps1.value;
			while (val > 1) {
				if (val % 2 != 0) {	i = -1;		break; }
				val /= 2;
				i++;
			}
			ps1_value = i;
		}
		else 	ps1_value = -1;
		print(intToString(ps1.value)+" "+intToString(ps2.value));
		i = 0;
		if (ps2.value != -1 && ps2.value != 0) {
			val = ps2.value;
			while (val > 1) {
				if (val % 2 != 0) {	i = -1;	break;	}
				val /= 2;
				i++;
			}
			ps2_value = i;
		}
		else ps2_value = -1;
		print("VALS "+intToString(ps1_value)+" "+intToString(ps1_value));

		if (ps1_value != -1 && ps2_value != -1) {
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
	print("FASTO");
	unsigned long long int stored;
	number++;
	if (!isRegister(ps1.stored)) stored = prepareRegister(ps1).index;
	else stored = ps1.stored;
	for (int i = 0; i < number; i++) addOutput(operation+" "+intToString(stored));
	return stored;
}

void organizeVariables() {
	for (auto i = variables.begin(); i != variables.end(); i++)
		if (i->length == -1) i->length = 0;

	for (int i = 1; i < variables.size(); i++) {
		Variable v = variables[i];
		int j = i - 1;
		while (j >= 0 && variables[j].length > v.length) {
			variables[j + 1] = variables[j];
			variables[j] = v;
			j--;
		}
	}
	unsigned long long int mem = 11;
	for (auto i = variables.begin(); i != variables.end(); i++) {
		if (i->length == 0) {
			i->length = -1;
			i->stored = mem++;
		}
		else {
			i->stored = mem;
			mem += i->length;
		}
	}
	memoryIndex = mem;
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
	else if (length == 0) yyerror("Declare array "+id+" of size 0!");
	else if (length > 0) {
		print("[declared array]: "+id+" | array length: "+intToString(length)+" | stored from: "+intToString(memoryIndex));
		memoryIndex += length;
	}
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
