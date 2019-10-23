import { createContext } from 'react';

export type HelpChipContent = {
  /**
   * Indicates a click of help chip content.
   * Returns whether the click event should be canceled.
   */
  onHelp(helpName: string): boolean;
};

export const HelpChipContext = createContext<HelpChipContent | undefined>(
  undefined,
);
