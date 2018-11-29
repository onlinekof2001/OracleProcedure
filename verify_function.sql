  CREATE OR REPLACE NONEDITIONABLE FUNCTION "SYS"."VERIFY_FUNCTION_DECATHLON"
(username varchar2,
  password varchar2,
  old_password varchar2)
  RETURN boolean IS
   n boolean;
   m integer;
   differ integer;
   isdigit boolean;
   ischar  boolean;
   ispunct boolean;
   db_name varchar2(40);
   digitarray varchar2(20);
   punctarray varchar2(25);
   chararray varchar2(52);
   i_char varchar2(10);
   simple_password varchar2(10);
   reverse_user varchar2(32);

BEGIN
   digitarray:= '0123456789';
   chararray:= 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

   -- Check for the minimum length of the password
   IF length(password) < 8 THEN
      raise_application_error(-20001, 'Password length less than 8');
   END IF;


   -- Check if the password is same as the username or username(1-100)
   IF NLS_LOWER(password) = NLS_LOWER(username) THEN
     raise_application_error(-20002, 'Password same as or similar to user');
   END IF;
   FOR i IN 1..100 LOOP
      i_char := to_char(i);
      if NLS_LOWER(username)|| i_char = NLS_LOWER(password) THEN
        raise_application_error(-20005, 'Password same as or similar to user nam
e ');
      END IF;
    END LOOP;

   -- Check if the password is same as the username reversed

   FOR i in REVERSE 1..length(username) LOOP
     reverse_user := reverse_user || substr(username, i, 1);
   END LOOP;
   IF NLS_LOWER(password) = NLS_LOWER(reverse_user) THEN
     raise_application_error(-20003, 'Password same as username reversed');
   END IF;

   -- Check if the password is the same as server name and or servername(1-100)
   select name into db_name from sys.v$database;
   if NLS_LOWER(db_name) = NLS_LOWER(password) THEN
      raise_application_error(-20004, 'Password same as or similar to server nam
e');
   END IF;
   FOR i IN 1..100 LOOP
      i_char := to_char(i);
      if NLS_LOWER(db_name)|| i_char = NLS_LOWER(password) THEN
        raise_application_error(-20005, 'Password same as or similar to server n
ame ');
      END IF;
    END LOOP;

   -- Check if the password is too simple. A dictionary of words may be
   -- maintained and a check may be made so as not to allow the words
   -- that are too simple for the password.
   IF NLS_LOWER(password) IN ('welcome1', 'database1', 'account1', 'user1234', '
password1', 'oracle123', 'computer1', 'abcdefg1', 'change_on_install','decathlon
','prod','prod.com') THEN
      raise_application_error(-20006, 'Password too simple');
   END IF;

   -- Check if the password is the same as oracle (1-100)
    simple_password := 'oracle';
    FOR i IN 1..100 LOOP
      i_char := to_char(i);
      if simple_password || i_char = NLS_LOWER(password) THEN
        raise_application_error(-20007, 'Password too simple ');
      END IF;
    END LOOP;

   -- Check if the password contains at least one letter, one digit
   -- 1. Check for the digit
   isdigit:=FALSE;
   m := length(password);
   FOR i IN 1..10 LOOP
      FOR j IN 1..m LOOP
         IF substr(password,j,1) = substr(digitarray,i,1) THEN
            isdigit:=TRUE;
             GOTO findchar;
         END IF;
      END LOOP;
   END LOOP;

   IF isdigit = FALSE THEN
      raise_application_error(-20008, 'Password must contain at least one digit,
 one character');
   END IF;
   -- 2. Check for the character
   <<findchar>>
   ischar:=FALSE;
   FOR i IN 1..length(chararray) LOOP
      FOR j IN 1..m LOOP
         IF substr(password,j,1) = substr(chararray,i,1) THEN
            ischar:=TRUE;
             GOTO endsearch;
         END IF;
      END LOOP;
   END LOOP;
   IF ischar = FALSE THEN
      raise_application_error(-20009, 'Password must contain at least one \
              digit, and one character');
   END IF;
   <<endsearch>>
   -- Check if the password differs from the previous password by at least
   -- 3 letters
   IF old_password IS NOT NULL THEN
     differ := length(old_password) - length(password);

     differ := abs(differ);
     IF differ < 3 THEN
       IF length(password) < length(old_password) THEN
         m := length(password);
       ELSE
         m := length(old_password);
       END IF;

       FOR i IN 1..m LOOP
         IF substr(password,i,1) != substr(old_password,i,1) THEN
           differ := differ + 1;
         END IF;
       END LOOP;

       IF differ < 3 THEN
         raise_application_error(-20011, 'Password should differ from the \
            old password by at least 3 characters');
       END IF;
     END IF;
   END IF;
   -- Everything is fine; return TRUE ;
   RETURN(TRUE);
END;