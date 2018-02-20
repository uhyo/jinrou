/**
 * Information of your job.
 */
export interface RoleInfo {
    /**
     * Name of current job.
     */
    jobname: string;
    /**
     * Descriptions provided to you.
     */
    desc: RoleDesc[];
    /**
     * Kind of speech available now.
     */
    speak: string[];
    /**
     * Content of will.
     */
    will: string | undefined;
}
export interface RoleDesc {
    /**
     * Name of role.
     */
    name: string;
    /**
     * Id of role.
     */
    type: string;
}

/**
 * State of speaking form.
 */
export interface SpeakState {
    /**
     * Size of comment.
     */
    size: 'small' | 'normal' | 'big';
    /**
     * Kind of speech.
     */
    kind: string;
    /**
     * Multiline or not.
     */
    multiline: boolean;
    /**
     * Whether will form is open.
     */
    willOpen: boolean;
}
