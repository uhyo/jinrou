export interface UserProfile {
  userid: string;
  name: string;
  comment: string;
  icon: string | null;
  mail: {
    /**
     * Present if changing to new mail address
     */
    new?: string;
    /**
     * Whether mail address is verified
     */
    verified: boolean;
    /**
     * Current maila ddress
     */
    address: string;
  };
}

export type NewsEntry = {
  time: number;
  message: string;
};

export type BanInfo = {
  reason: string;
  /**
   * Expiry time in (ISO8601 string format)
   */
  expires?: string;
};

/**
 * Info of current prize,
 */
export type PrizeInfo = {
  /**
   * Number of owned prizes.
   */
  totalNumber: number;
  /**
   * current katagaki
   */
  currentPrizeData?: string;
};

export type ProfileSaveQuery = {
  /**
   * Current password.
   */
  password: string;
  /**
   * new name.
   */
  name?: string;
  /**
   * new comment.
   */
  comment?: string;
  /**
   * new mail address.
   */
  mail?: string;
};

export type ChangePasswordQuery = {
  newPassword: string;
  newPassword2: string;
  currentPassword: string;
};
