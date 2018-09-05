export type FormType = 'required' | 'optional' | 'optionalOnce';
export interface FormDesc {
  /**
   * Type of this form.
   */
  type: string;
  /**
   * Options for this form.
   */
  options: FormOption[];
  /**
   * Type of requiredness.
   */
  formType: FormType;
  /**
   * ID of owner of this form.
   */
  objid: string;
}
export interface FormOption {
  /**
   * Label of this option.
   */
  name: string;
  /**
   * Value sent to server.
   */
  value: string;
}
