import { createContext } from 'react';

export type HelpChipContent = {
  /**
   * Indicates a click of help chip content.
   * Returns whether the click event should be canceled.
   */
  onHelp(helpName: string): boolean;
  /**
   * Returns whether given help chip area is available.
   */
  isAvailable(helpName: string): boolean;
};

export const HelpChipContext = createContext<HelpChipContent | undefined>(
  undefined,
);
