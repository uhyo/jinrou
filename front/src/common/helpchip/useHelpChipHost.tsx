import { HelpChipContext, HelpChipContent } from './context';
import { useMemo, useState } from 'react';

/**
 * Define a host of helpchip.
 * `handler` is called only once for each helpName.
 */
export function useHelpChipHost(handler: (helpName: string) => void) {
  const [helpShownFlags, setHelpShownFlags] = useState<
    Partial<Record<string, boolean>>
  >({});

  const helpChipContent = useMemo<HelpChipContent>(
    () => ({
      onHelp(helpName) {
        // show help only when this is the first time
        if (helpShownFlags[helpName]) {
          return false;
        }
        setHelpShownFlags({
          ...helpShownFlags,
          [helpName]: true,
        });
        handler(helpName);
        return true;
      },
      isAvailable(helpName) {
        return !helpShownFlags[helpName];
      },
    }),
    [handler, helpShownFlags],
  );

  return {
    Provider: HelpChipContext.Provider,
    helpChipContent,
  };
}
