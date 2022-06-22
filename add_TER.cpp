#include<iostream>
#include<fstream>
#include<sstream>
#include<string>
#include<iomanip>
#include<cmath>
using namespace std;

const unsigned int MAX_LINES_PDB = 50000;
const unsigned int MAX_LINES_LOG = 10000;

struct Molecule_info
{
    string ATOM, atomName, resName, chainID, element, ocpy, bfac;
    int serial, resSeq;
    float x, y, z;
};

Molecule_info Prot[40000];

int main()
{
    ifstream infile1, infile2;
    infile1.open("xxxx_mod_1.pdb", ios::in);
    infile2.open("xxxx_mod_1.log", ios::in);

    if (!infile1)
    {
        cerr << "Open infile1 failure!" << endl;
        return -1;
    }

    // 将蛋白质信息格式化存入结构数组
    int i = 1, t;
    string tmpStr;
    string *PDB_line = new string[MAX_LINES_PDB];
    static const size_t npos = -1;
    size_t position;
    while (!infile1.eof())
    {
        getline(infile1, tmpStr);
        PDB_line[i] = tmpStr;
        istringstream re_infile1(tmpStr);
        position = PDB_line[i].find("ATOM");
        if (position != string::npos)
        {
            re_infile1 >> Prot[i].ATOM >> Prot[i].serial >> Prot[i].atomName >> Prot[i].resName >> setw(1) >> Prot[i].chainID >> Prot[i].resSeq >> Prot[i].x >> Prot[i].y >> Prot[i].z >> setw(4) >> Prot[i].ocpy >> Prot[i].bfac >> Prot[i].element;
        }
        i++;
    }
    t = i - 2;
    infile1.close();

    if (!infile2)
    {
        cerr << "Open infile2 failure!" << endl;
        return -1;
    }

    // 从蛋白质处理日志中提取GAP信息
    i = 1;
    int j = 1;
    int res_gap[100];
    string *LOG_line = new string[MAX_LINES_LOG];
    while (!infile2.eof())
    {
        getline(infile2, tmpStr);
        LOG_line[i] = tmpStr;
        istringstream re_infile2(tmpStr);
        string s;
        position = LOG_line[i].find("gap");
        if (position == 0)
        {
            int k = 1;
            while (re_infile2 >> s)
            {
                if (k == 7)
                {
                    res_gap[j] = atoi(s.c_str());
                }
                k++;
            }
            j++;
        }
        i++;
    }
    infile2.close();

    ofstream outfile;
    outfile.open("xxxx_mod_2.pdb", ios::out | ios::ate);

    // 根据日志信息为原PDB文件中的GAP添加TER标志，并获取蛋白质的残基总数
    j = 1;
    int N_res = 0;
    for (i = 1; i <= t; i++)
    {
        position = PDB_line[i].find("ATOM");
        if (position != string::npos)
        {
            outfile << left << setw(6) << Prot[i].ATOM << right << setw(5) << Prot[i].serial << "  " << left << setw(3) << Prot[i].atomName << " " << setw(3) << Prot[i].resName << " " << Prot[i].chainID << right << setw(4) << Prot[i].resSeq << "    " << setw(8) << fixed << setprecision(3) << Prot[i].x << setw(8) << fixed << setprecision(3) << Prot[i].y << setw(8) << fixed << setprecision(3) << Prot[i].z << setw(6) << fixed << setprecision(2) << Prot[i].ocpy << setw(6) << fixed << setprecision(2) << Prot[i].bfac << "          " << setw(2) << Prot[i].element << endl;
            if (Prot[i].resSeq > N_res)
                N_res = Prot[i].resSeq;
            position = PDB_line[i + 1].find("ATOM");
            if (position != string::npos)
            {
                if (Prot[i].resSeq != Prot[i + 1].resSeq && Prot[i].resSeq == res_gap[j])
                {
                    outfile << "TER" << endl;
                    j++;
                }
            }
        }
        else
            outfile << PDB_line[i] << endl;
    }
    outfile.close();

    delete [] PDB_line;
    delete [] LOG_line;

    cout << N_res << endl;

    return 0;
}
