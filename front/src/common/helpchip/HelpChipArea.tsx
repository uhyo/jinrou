import { FunctionComponent, useContext, useCallback } from 'react';
import { HelpChipContext } from './context';
import React from 'react';
import styled from '../../util/styled';

interface Props {
  /**
   * Name of help which is emitted from this help chip area.
   */
  helpName: string;
  /**
   * type of surronding block.
   */
  display?: 'block' | 'inline-block' | 'inline';
}

export const HelpChipArea: FunctionComponent<Props> = ({
  helpName,
  display = 'inline-block',
  children,
}) => {
  const helpChipContent = useContext(HelpChipContext);

  const clickHandler = useCallback(
    (e: React.SyntheticEvent<HTMLElement>) => {
      if (!helpChipContent) {
        return;
      }
      const shouldCancel = helpChipContent.onHelp(helpName);
      if (shouldCancel) {
        e.stopPropagation();
      }
    },
    [helpName, helpChipContent],
  );

  if (display === 'block') {
    return <div onClickCapture={clickHandler}>{children}</div>;
  } else if (display === 'inline-block') {
    return <InlineBlock onClickCapture={clickHandler}>{children}</InlineBlock>;
  } else {
    return <span onClickCapture={clickHandler}>{children}</span>;
  }
};

const InlineBlock = styled.span`
  display: inline-block;
`;
