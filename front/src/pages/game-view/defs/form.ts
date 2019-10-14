export type FormType = 'required' | 'optional' | 'optionalOnce';
/**
 * Description of one form.
 */
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
  /**
   * Data attached to this formdesc.
   */
  data: unknown;
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

/**
 * Specially-defined form data.
 */
interface SpecialFormData {
  // 人狼の襲撃
  _Werewolf: {
    /**
     * 残りの襲撃可能人数
     */
    remains: number;
  };
  // 竜騎士
  DragonKnight: {
    /**
     * 襲撃を既に使用したか
     */
    killUsed: boolean;
  };
  // 歌人
  Poet1: {
    /**
     * 歌のスタイル（1行あたりの文字数）
     */
    poemStyle: number[];
  };
  Poet2: {
    /**
     * 送る相手の名前
     */
    target: string;
    /**
     * 歌のスタイル（1行あたりの文字数）
     */
    poemStyle: number[];
  };
  // 課金者
  GachaAddicted_Premium: {
    /**
     * 残り課金可能数
     */
    votes: number;
  };
  GachaAddicted_Commit: {
    /**
     * 変化先役職
     */
    job: string;
  };
}
/**
 * Type of data for specific type.
 */
export type FormDataType<T extends string> = T extends keyof SpecialFormData
  ? SpecialFormData[T]
  : undefined;

/**
 * Get data of form whose form type is known.
 */
export function getFormData<D extends FormDesc>(
  data: D,
): FormDataType<D['type']> {
  return data.data as any;
}
