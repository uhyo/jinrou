/**
 * confirmation dialog.
 */
export interface IConfirmDialog {
    /**
     * Title of dialog.
     */
    title?: string;
    /**
     * Whether this is a modal window.
     */
    modal?: boolean;
    /**
     * Message of dialog.
     */
    message: string;
    /**
     * yes button.
     */
    yes?: string;
    /**
     * no button.
     */
    no?: string;
}
