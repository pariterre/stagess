/* Initialize the transaction */
START TRANSACTION;

/*********************/
/*** ADMIN SECTION ***/
/*********************/

ALTER TABLE students
    ADD COLUMN can_have_multiple_internships BOOLEAN NOT NULL DEFAULT FALSE
        AFTER teacher_in_charge_id;


/* Terminate the transaction */
COMMIT;
