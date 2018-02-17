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

