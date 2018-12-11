import { Prize } from '../defs';
import * as React from 'react';
import { PrizeTip } from '../elements';

/**
 * Component which shows one prize.
 */
export const OnePrize = ({ prize }: { prize: Prize }) => {
  return (
    <li>
      <PrizeTip>{prize.name}</PrizeTip>
    </li>
  );
};
