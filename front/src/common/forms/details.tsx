import * as React from 'react';
import { useState } from 'react';
import styled from '../../util/styled';
import { helperTextColor } from '../color';
import { FontAwesomeIcon } from '../../util/icon';

/**
 * Custom details for use in form.
 */
export const DetailsInner = styled.div`
  color: ${helperTextColor};
`;

export const Details: React.FunctionComponent<{
  summaryOpen: string;
  summaryClosed: string;
  defaultOpen?: boolean;
}> = ({ summaryOpen, summaryClosed, children, defaultOpen = false }) => {
  const [open, setOpen] = useState(defaultOpen);

  return (
    <DetailsInner>
      <div role="button" tabIndex={0} onClick={() => setOpen(open => !open)}>
        <FontAwesomeIcon icon={open ? 'minus-square' : 'plus-square'} />{' '}
        {open ? summaryOpen : summaryClosed}
      </div>
      <div
        aria-hidden={open ? 'true' : 'false'}
        style={{
          display: open ? 'block' : 'none',
        }}
      >
        {children}
      </div>
    </DetailsInner>
  );
};
