import { HelpChipContext, HelpChipContent } from './context';
import { useMemo, useState, FunctionComponent } from 'react';
import React from 'react';

/**
 * Define a host of helpchip.
 * `handler` is called only once for each helpName.
 */
export function useHelpChipHost(handler: (helpName: string) => void) {
  const [helpShownFlags] = useState<Partial<Record<string, boolean>>>(
    () => ({}),
  );

  const obj = useMemo<HelpChipContent>(
    () => ({
      onHelp(helpName) {
        // show help only when this is the first time
        if (helpShownFlags[helpName]) {
          return false;
        }
        helpShownFlags[helpName] = true;
        handler(helpName);
        return true;
      },
      isAvailable(helpName) {
        return !helpShownFlags[helpName];
      },
    }),
    [handler],
  );

  const Provider = useMemo<FunctionComponent<{}>>(
    () => {
      const P = HelpChipContext.Provider;
      return ({ children }) => <P value={obj}>{children}</P>;
    },
    [obj],
  );

  return {
    Provider,
  };
}
