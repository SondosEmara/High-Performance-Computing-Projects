Use [ExamSystem]
  
/*
TEST DATA 

INSERT INTO dbo.Student
VALUES ('Sondos',Null,Null,1),
	 ('Salma',Null,Null,2),
	 ('sarah',Null,Null,3),
	 ('sarah',Null,Null,4),
	 ('sarah',Null,Null,5);


INSERT INTO dbo.Course
VALUES  (111,'OOP'),
	(222,'DS');

INSERT INTO dbo.StudentCourse
VALUES  (1,111,Null,Null,Null,Null,Null),
	(2,111,Null,Null,Null,Null,Null),
	(3,111,Null,Null,Null,Null,Null),
	(4,222,Null,Null,Null,Null,Null),
	(5,222,Null,Null,Null,Null,Null);

INSERT INTO dbo.Question
VALUES (1, 'Multiple Choice', 2, '12:00:00', 'easy', '1', 111),
       (2, 'True/False', 1, '13:00:00', 'medium', '2', 111),
       (3, 'Multiple Choice', 3, '14:00:00', 'hard', '3', 111),


	   (4, 'Multiple Choice', 2, '12:00:00', 'easy', '4', 111),
       (5, 'True/False', 1, '13:00:00', 'medium', '5', 111),
       (6, 'Multiple Choice', 3, '14:00:00', 'hard', '6', 111),


	   (7, 'Multiple Choice', 2, '12:00:00', 'easy', '7', 111),
       (8, 'True/False', 1, '13:00:00', 'medium', '8', 111),
       (9, 'Multiple Choice', 3, '14:00:00', 'hard', '9', 111),


	   (10, 'Multiple Choice', 2, '12:00:00', 'easy', '7', 111),
       (11, 'True/False', 1, '13:00:00', 'medium', '8', 111),
       (12, 'Multiple Choice', 3, '14:00:00', 'hard', '9', 111),

	   (13, 'Multiple Choice', 2, '12:00:00', 'easy', '7', 111),
       (14, 'True/False', 1, '13:00:00', 'medium', '8', 111),
       (15, 'Multiple Choice', 3, '14:00:00', 'hard', '9', 111),

	   (16, 'Multiple Choice', 2, '12:00:00', 'easy', '16', 111),
       (17, 'True/False', 1, '13:00:00', 'medium', '17', 111),
       (18, 'Multiple Choice', 3, '14:00:00', 'hard', '18', 111),

	   (19, 'Multiple Choice', 2, '12:00:00', 'easy', '19', 222),
       (20, 'True/False', 1, '13:00:00', 'medium', '20', 222),
       (21, 'Multiple Choice', 3, '14:00:00', 'hard', '21', 222);
*/


ALTER FUNCTION getStudents(@courseId INT)
RETURNS TABLE
AS
RETURN (
    SELECT StudentID
    FROM StudentCourse
    WHERE CourseID = @courseId
);

ALTER PROC  Exams_Initialization 
   (@Type varchar(20),
	@TotalPoints int ,
	@TotalTime time(7),
    @ScheduledTime time(7),
    @SuccessPrecent float,
    @InstID int,
    @courseId int)
AS
BEGIN
	Insert INTO Exam
	select @Type, @TotalPoints, @TotalTime , @ScheduledTime, @SuccessPrecent, @InstID, StudentID, NULL, NULL, @courseId
	from getStudents(@courseId);	
END

--EXEC Exams_Iteration 222 ,1,2,1,First_Exam;

ALTER PROC Exams_Iteration
        @courseId int,
		@EasyNo int,
		@HardNo int,
		@MediamNo int,
		@Type varchar(20)
AS
BEGIN
		declare c1 cursor
		FOR SELECT ID FROM Exam WHERE (CourseID=@courseId) and ([Type]=@Type)
	    FOR read only 

	    declare @id int
		open c1
        fetch c1 into @id
		while @@FETCH_STATUS=0
		begin
			EXEC Peek_Questions @id,@courseId,@EasyNo,@MediamNo ,@HardNo
			fetch c1 into @id
		end
		close c1
		deallocate c1	
END


/*
EXEC Peek_Questions 74,222,1,2,1
EXEC Peek_Questions 75,222,1,2,1
*/
ALTER PROC Peek_Questions(@examId INT,@courseId INT,@easyNo INT,@mediumNo INT,@hardNo INT)
  AS
  BEGIN
    	INSERT INTO ExamQuestion
		SELECT @examId,ID
        FROM 
		(
              SELECT ID,CourseID,Difficulty,ROW_NUMBER() 
			  OVER (PARTITION BY Difficulty ORDER BY NEWID()) AS rowNum
              FROM Question
			  WHERE CourseID=@courseId
        ) As Partion_Res

        WHERE (Difficulty = 'easy' AND rowNum <= @easyNo) OR
			  (Difficulty = 'medium' AND rowNum <= @mediumNo) OR
			  (Difficulty = 'hard' AND rowNum <= @hardNo) 
				 
  END

  
 --Delete From ExamQuestion


 --That Start Point Call only that Porocdurce
 ALTER PROCEDURE Generate_Exam
        @Type varchar(20),
		@TotalPoints int ,
		@TotalTime time(7),
		@ScheduledTime time(7),
		@SuccessPrecent float,
		@InstID int,
		@courseId int,
		@EasyNo int,
		@MediamNo int,
		@HardNo int
As 
Begin

    DECLARE @ifSucess bit=1
	BEGIN TRY
		EXEC Exams_Initialization @Type,@TotalPoints,@TotalTime,@ScheduledTime,@SuccessPrecent,@InstID,@courseId;
		EXEC Exams_Iteration @courseId ,@EasyNo,@HardNo,@MediamNo,@Type;
	END TRY
    BEGIN CATCH
        SET @ifSucess = 0
    END CATCH
    RETURN @ifSucess
END



 EXEC Generate_Exam 'First_Exam',50,'2:0:0','12:34:56',50,1, 111, 3,2,3;
 EXEC Generate_Exam 'First_Exam',50,'2:0:0','12:34:56',50,1, 222, 1,2,1;


