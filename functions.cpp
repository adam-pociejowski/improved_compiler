#include "functions.h"

vector<string> output;
vector<string> errors;
vector<Variable> variables;
struct Register registers[10];
unsigned long long int memoryIndex = 10;
unsigned long long int k = 0;
int error = 0;
int flag = 1;

/** OPTIMALIZATION OPTIONS **/
int superVarRegistersAmount = 5; 				 //Max amount of registers using to keep variables
int superIteratorRegistersAmount = 0;    //Min amount of registers using to keep iterators
int memoryStart = 10;   								 //10 is first adress of memory (0)



void saveLoopCounter(ParserVar p) {
	print(intToString(p.stored));
	printVariables();
	if (isRegister(p.stored))	addOutput("DEC "+intToString(p.stored));
	else {
		Register reg = getFreeRegister(true);
		Register reg2 = getFreeRegister(true);
		setValueInRegister(p.stored - 10, reg.index);
		addOutput("LOAD "+intToString(reg2.index)+" "+intToString(reg.index));
		addOutput("DEC "+intToString(reg2.index));
		addOutput("STORE "+intToString(reg2.index)+" "+intToString(reg.index));
		freeRegister(reg.index, true);
		freeRegister(reg2.index, true);
	}
}


unsigned long long int addLoopCounter(Register reg) {
	if (superIteratorRegistersAmount > 0) {
		reg.iterator = true;
		reg.id = "loopCounter";
		setRegister(reg, true);
		return reg.index;
	}
	else {
		Register reg2 = getFreeRegister(true);
		setValueInRegister(memoryIndex - 10, reg2.index);
		addOutput("STORE "+intToString(reg.index)+" "+intToString(reg2.index));
		freeRegister(reg2.index, true);
		return memoryIndex++;
	}
}


unsigned long long int addIterator(string id) {
	unsigned long long int index = memoryStart;
	Variable v;
	v.id = id;
	v.value = 0;

	if (superIteratorRegistersAmount > 0) {
		Register reg = getFreeRegister(true);
		reg.iterator = true;
		setSuperVarInRegister(reg, v);
		index = reg.index;
		v.stored = reg.index;
		superIteratorRegistersAmount--;
	}
	else {
		if (variables.size() > 0) {
			for (auto i = variables.begin(); i != variables.end(); i++) {
				if (i->stored < index && !isRegister(i->stored))	index = i->stored;
			}
			if (index == 10) {
				v.stored = memoryIndex;
				index = memoryIndex++;
			}
			else v.stored = --index;
		}
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
	Register reg_2 = getFreeRegister(true);
	setValueInRegister(stored - 10, reg_2.index);
	addOutput("STORE "+intToString(reg.index)+" "+intToString(reg_2.index));
	freeRegister(reg_2.index, true);
}


Register getIterator(unsigned long long int stored) {
	Register reg = getFreeRegister(true);
	Register reg_2 = getFreeRegister(true);
	setValueInRegister(stored - 10, reg.index);
	addOutput("LOAD "+intToString(reg_2.index)+" "+intToString(reg.index));
	return reg_2;
}


void storeVariable(ParserVar p1, ParserVar p2) {
	Variable v = getVariable(p1.name);
	v.value = 0;
	setVariable(v);
	if (p1.stored >= 10) {
		if (p1.index != -1) {	//Storing in array var(var1)
			if (isRegister(p1.index)) { //array var(superVar)
				Register reg1 = getFreeRegister(true);
				setValueInRegister(p1.stored - 10, reg1.index);
				addOutput("ADD "+intToString(reg1.index)+" "+intToString(p1.index));
				Register reg2 = prepareRegister(p2);
				addOutput("STORE "+intToString(reg2.index)+" "+intToString(reg1.index));
				freeRegister(reg1.index, true);
			}
			else {
				Register reg1 = getFreeRegister(true);
				Register reg2 = getFreeRegister(true);
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
		}
		else {
			Register reg = getFreeRegister(true);
			setValueInRegister(p1.stored - 10, reg.index);
			addOutput("STORE "+intToString(p2.stored)+" "+intToString(reg.index));
			freeRegister(reg.index, false);
		}
	}
	else if (v.superVar) {
		if (p1.stored != p2.stored) addOutput("COPY "+intToString(v.stored)+" "+intToString(p2.stored)); // superVar = register
	}
	else {
		addOutput("STORE "+intToString(p2.stored)+" "+intToString(p1.stored));
		registers[p1.stored].toReset = true;
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
		if (isRegister(pv.index)) { //Array var(superVar)
			reg = getFreeRegister(true);
			Register reg2 = getFreeRegister(true);
			setValueInRegister(pv.stored - 10, reg2.index);
			addOutput("ADD "+intToString(reg2.index)+" "+intToString(pv.index));
			addOutput("LOAD "+intToString(reg.index)+" "+intToString(reg2.index));
			freeRegister(reg2.index, true);
		}
		else { //Array var(var)
			reg = getFreeRegister(true);
			Register reg2 = getFreeRegister(true);
			setValueInRegister(pv.index - 10, reg2.index);
			addOutput("LOAD "+intToString(reg.index)+" "+intToString(reg2.index));
			addOutput("RESET "+intToString(reg2.index));
			setValueInRegister(pv.stored - 10, reg2.index);
			addOutput("ADD "+intToString(reg2.index)+" "+intToString(reg.index));
			addOutput("LOAD "+intToString(reg.index)+" "+intToString(reg2.index));
			freeRegister(reg2.index, true);
		}
	}
	else if (pv.stored == -1) {  //Value
		reg = getFreeRegister(true);
		setValueInRegister(pv.value, reg.index);
	}
	else if (isRegister(pv.stored)) return registers[pv.stored];	//Value is already in register
	else if (pv.stored >= 10) {
		reg = getFreeRegister(true);
		reg.id = pv.name;
		Register reg_2 = getFreeRegister(true);		//Register where stored is memory adress
		setValueInRegister(pv.stored - 10, reg_2.index);
		addOutput("LOAD "+intToString(reg.index)+" "+intToString(reg_2.index));
		freeRegister(reg_2.index, false);
	}
	reg.toReset = true;
	return reg;
}


int setValueInRegister(unsigned long long int value, unsigned long long int reg_index) {
	vector<string> commands;
	unsigned long long int a = value;
	if (value > 0) registers[reg_index].toReset = true;
	while (a > 0) {
		if (a < value) commands.push_back("SHL "+intToString(reg_index));
		if (a % 2 == 1) commands.push_back("INC "+intToString(reg_index));
		a /= 2;
	}
	for (int i = commands.size()-1; i >= 0; i--) addOutput(commands[i]);
	return reg_index;
}


void storeIterator(ParserVar p, Register reg) {
	if (p.stored == reg.index) {}
	else if (isRegister(p.stored))	addOutput("COPY "+intToString(p.stored)+" "+intToString(reg.index));
	else {
		Register reg_2 = getFreeRegister(true);
		setValueInRegister(p.stored - 10, reg_2.index);
		addOutput("STORE "+intToString(reg.index)+" "+intToString(reg_2.index));
		freeRegister(reg_2.index, true);
		registers[reg.index].iterator = false;
	}
	freeRegister(reg.index, true);
}


void deleteIterator(ParserVar p) {
	if (isRegister(p.stored)) deleteSuperVarFromRegister(getRegisterByIndex(p.stored));
	Variable v;
	v.id = p.name;
	v.iterator = true;
	deleteVariable(v);
}


void deleteIterator(ParserVar iterator, ParserVar counter) {
	if (isRegister(iterator.stored)) deleteSuperVarFromRegister(getRegisterByIndex(iterator.stored));
	Variable v;
	v.id = iterator.name;
	v.iterator = true;
	deleteVariable(v);
	if (isRegister(counter.stored)) {
		registers[counter.stored].iterator = false;
		registers[counter.stored].isFree = true;
		registers[counter.stored].toReset = false;
		registers[counter.stored].id = "";
		superIteratorRegistersAmount++;
		printVariables();
	}
}


void resetAllRegisters(bool reset) {
	for (int i = 0; i < 10; i++) freeRegister(i, false);
}


void freeRegister(int reg_index, bool reset) {
	if (!getRegisterByIndex(reg_index).superVar) {
		if (!getRegisterByIndex(reg_index).iterator) {
			if (reset) registers[reg_index].toReset = true;
			registers[reg_index].isFree = true;
			registers[reg_index].id = "";
		}
	}
}


Register getFreeRegister(bool initReset) {
	for (int i = 0; i < 10; i++) {
		if (registers[i].isFree) {
			if (registers[i].toReset) {
				if (initReset) addOutput("RESET "+intToString(i));
				registers[i].toReset = false;
			}
			registers[i].isFree = false;
			return registers[i];
		}
	}
	yyerror("All registers in use");
}


void setRegister(Register reg, bool positive) {
	reg.toReset = positive;
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
		reg = getFreeRegister(true);
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
		reg = getFreeRegister(true);
		return reg.index;
	}
	else if ((ps1.stored == -1 && ps2.stored == -1) && (ps1.value != -1 && ps2.value != -1)) {  //Situation 6 - 3
		reg = getFreeRegister(true);
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


unsigned long long int quickMultiplication(ParserVar ps1, ParserVar ps2, int optimalization) {
	if (ps1.value > 0 || ps2.value > 0) {
		int ps1_value = -1, ps2_value = -1;
		ps1_value = getLog(ps1.value);
		ps2_value = getLog(ps2.value);

		if (optimalization == 1 && ps2_value >= 0) {  //a := a * 2;
			for (int i = 0; i < ps2_value; i++) addOutput("SHL "+intToString(ps1.stored));
			return ps1.stored;
		}
		else if (optimalization == 2 && ps1_value >= 0) {
			for (int i = 0; i < ps1_value; i++) addOutput("SHL "+intToString(ps2.stored));
			return ps2.stored;
		}
		else if (ps1_value != -1 && ps2_value != -1) {
			if (ps1_value < ps2_value) return quickOperationsPrinter("SHL", ps1_value, ps2, ps1);
			else return quickOperationsPrinter("SHL", ps2_value, ps1, ps2);
			return -1;
		}
		else if (ps1_value > -1) return quickOperationsPrinter("SHL", ps1_value, ps2, ps1);
		else if (ps2_value > -1) return quickOperationsPrinter("SHL", ps2_value, ps1, ps2);
	}
	return -1;
}


unsigned long long int quickDivision(ParserVar ps1, ParserVar ps2, int optimalization) {
	if (ps1.value > 0 || ps2.value > 0) {
		int ps2_value = -1;
		ps2_value = getLog(ps2.value);

		if (optimalization == 1 && ps2_value >= 0) {  //a := a / 2;
			for (int i = 0; i < ps2_value; i++) addOutput("SHR "+intToString(ps1.stored));
			return ps1.stored;
		}
		else if (ps2_value > -1) return quickOperationsPrinter("SHR", ps2_value, ps1, ps2);
	}
	return -1;
}


unsigned long long int quickOperationsPrinter(string operation, int number, ParserVar ps1, ParserVar ps2) {
	unsigned long long int stored;
	if (!isRegister(ps1.stored)) stored = prepareRegister(ps1).index;
	else {
		Register reg = getFreeRegister(false);
		setRegister(reg, true);
		addOutput("COPY "+intToString(reg.index)+" "+intToString(ps1.stored));
		stored = reg.index;
	}
	for (int i = 0; i < number; i++) addOutput(operation+" "+intToString(stored));
	return stored;
}


int getLog(unsigned long long int value) {
	int i = 0;
	if (value != -1 && value != 0) {
		while (value > 1) {
			if (value % 2 != 0) {
				i = -1;
				break;
			}
			value /= 2;
			i++;
		}
		return i;
	}
	else return -1;
}


Register superVarOperations(ParserVar p1, ParserVar p2) {
	Register reg;
	if (isRegister(p1.stored)) {  //We have in at least one on these registers superVar and we don't cant to lost them so we need to copy
		addOutput("COPY "+intToString(reg.index)+" "+intToString(p1.stored));
		reg = prepareRegister(p2);
	}
	else {
		addOutput("COPY "+intToString(reg.index)+" "+intToString(p2.stored));
		reg = prepareRegister(p1);
	}
	return reg;
}


void organizeVariables() {
	for (auto i = variables.begin(); i != variables.end(); i++)
		if (i->length == -1) i->length = 0;

	int superVarAmount = 0;
	//Counting how many variables we have
	for (auto i = variables.begin(); i != variables.end(); i++) if (i->length == 0) superVarAmount++;

	for (int i = 1; i < variables.size(); i++) {
		Variable v = variables[i];
		int j = i - 1;
		while (j >= 0 && variables[j].length > v.length) {
			variables[j + 1] = variables[j];
			variables[j] = v;
			j--;
		}
	}
	if (superVarAmount > superVarRegistersAmount) superVarAmount = superVarRegistersAmount;
	else if (superVarAmount < superVarRegistersAmount) superIteratorRegistersAmount += superVarRegistersAmount - superVarAmount;
	for (int i = 0; i < superVarAmount; i++) {
		registers[i].toReset = false;
		registers[i].isFree = false;
		setSuperVarInRegister(registers[i], variables[i]);
	}

	unsigned long long int mem = memoryStart;
	for (auto i = variables.begin(); i != variables.end(); i++) {
		if (i->length == 0 && i->stored >= 10) {
			i->length = -1;
			i->stored = mem++;
		}
		else if (i->length > 0) {
			i->stored = mem;
			mem += i->length;
		}
		else i->length = -1;
	}
	memoryIndex = mem;
}


void setSuperVarInRegister(Register reg, Variable v) {
	reg.id = v.id;
	reg.superVar = true;
	v.stored = reg.index;
	v.superVar = true;
	setRegister(reg, true);
	setVariable(v);
}


void deleteSuperVarFromRegister(Register reg) {
	if (reg.iterator) superIteratorRegistersAmount++;
	reg.id = "";
	reg.superVar = false;
	reg.iterator = false;
	setRegister(reg, true);
	freeRegister(reg.index, true);
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
		for (int i = 0; i < 10; i++) {
			cout<<"i: "<<i<<" | isFree: "<<registers[i].isFree<<" | id: "<<registers[i].id<<" | toReset: "<<registers[i].toReset<<" | iterator: "<<registers[i].iterator<<" | superVar "<<registers[i].superVar<<endl;
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
