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
