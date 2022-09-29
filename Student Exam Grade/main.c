#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>
#define SendDataTag 2001
#define ReturnDataTag 2002

main(int argc, char **argv)
{
    int processId,processNum,retV,partialResult=0,i;
    MPI_Status status;
    //The first process(Master) will call it to make a process(child).
    retV=MPI_Init(&argc, &argv);
    //get the process id(rank).
    retV=MPI_Comm_rank(MPI_COMM_WORLD, &processId);
    //get total number of process that user will enter it.
    retV=MPI_Comm_size(MPI_COMM_WORLD, &processNum);

    //check if the process is master or not
    if(processId==0)
    {
        //process Work the number of students that will be take for each process.
        int sum=0,processWorkNum=-1,studentCount,pId,endIndex=0,startIndex,i=0;
        int studIds[100],studGrades[100];
        char line[100];

        //open file
        FILE *fp =fopen("/shared/students.txt","r");
        if(fp==NULL)
            printf("File Not Open");

        //read from file
        while (fgets(line, 100, fp))
        {
            sscanf(line, "%d %d", &studIds[i], &studGrades[i]);
            if(isspace(line[0]))
                break;
            i++;
        }

        //divide a work between all other processes.
        //studentCount is the number of student in file.
        studentCount=i;

        /*check if the user enter a process > student count
          then if that exist we will divide work only in the
          process count==studentCount
        */
        if(studentCount<(processNum-1))
        {
            processWorkNum=1;
        }
        else if(processNum!=1)
            processWorkNum=studentCount/(processNum-1);


        //send the work after divided to the process.
        for(pId = 1; pId <processNum; pId++)
        {
            if(studentCount<pId)
                processWorkNum=0;
            startIndex=endIndex;
            endIndex=startIndex+processWorkNum;

            retV = MPI_Send( &processWorkNum,1, MPI_INT,
                             pId, SendDataTag, MPI_COMM_WORLD);

            retV = MPI_Send( &studIds[startIndex],processWorkNum, MPI_INT,
                             pId, SendDataTag, MPI_COMM_WORLD);

            retV = MPI_Send( &studGrades[startIndex],processWorkNum, MPI_INT,
                             pId, SendDataTag, MPI_COMM_WORLD);

        }


        /*this mean the process have the
          same work but still exist a student
          not manipulation.then the master will make it.
        */
        if(studentCount!=(processNum-1)&&processWorkNum!=0)
        {
            for( i = endIndex; i <studentCount; i++)
            {
                if(studGrades[i]>=60)
                {
                    printf("%i Passed The Exam \n",studIds[i]);
                    sum++;
                }
                else
                {
                    printf("%i Failed.Please Repeat The Exam \n",studIds[i]);

                }
            }
        }


        //Receive the result from each process.
        for(pId = 1; pId < processNum; pId++)
        {
            retV=MPI_Recv( &partialResult, 1, MPI_LONG, MPI_ANY_SOURCE,
                           ReturnDataTag, MPI_COMM_WORLD, &status);
			
            sum += partialResult;
        }
        printf("Total Number of Students passed the exam is %i out of %i \n",sum,studentCount);
    }
    //part child process.
    else
    {
        int arraySize=0;
        retV = MPI_Recv( &arraySize, 1, MPI_INT,
                         0, SendDataTag, MPI_COMM_WORLD, &status);
        int studId[arraySize];
        int grades[arraySize];

        //Receive the data from the master.
        retV = MPI_Recv( &studId, arraySize, MPI_INT,
                         0, SendDataTag, MPI_COMM_WORLD, &status);

        retV = MPI_Recv( &grades, arraySize, MPI_INT,
                         0, SendDataTag, MPI_COMM_WORLD, &status);

        int k;
        for(k = 0; k < arraySize; k++)
        {
            if(grades[k] < 60)
            {
                printf("%d Failed.Please Repeat The Exam \n", studId[k]);
            }
            else
            {
                printf("%d Passed The Exam \n", studId[k]);
                partialResult++;
            }

        }
            retV = MPI_Send( &partialResult, 1, MPI_LONG,0,
                         ReturnDataTag, MPI_COMM_WORLD);
    }
    //release MPI.
    retV=MPI_Finalize();
}













































