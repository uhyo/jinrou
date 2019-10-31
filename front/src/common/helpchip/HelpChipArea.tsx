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
  display = 'inline',
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

  const isAvailable = helpChipContent
    ? helpChipContent.isAvailable(helpName)
    : false;

  if (display === 'block') {
    return (
      <Block isAvailable={isAvailable} onClickCapture={clickHandler}>
        {children}
      </Block>
    );
  } else if (display === 'inline-block') {
    return (
      <InlineBlock isAvailable={isAvailable} onClickCapture={clickHandler}>
        {children}
      </InlineBlock>
    );
  } else {
    return (
      <Span isAvailable={isAvailable} onClickCapture={clickHandler}>
        {children}
      </Span>
    );
  }
};

interface StyleProps {
  isAvailable: boolean;
}

const cursorStyle = (props: StyleProps) =>
  props.isAvailable ? 'help' : 'inherit';

const Block = styled.div<StyleProps>`
  cursor: ${cursorStyle};
`;

const InlineBlock = styled.span<StyleProps>`
  display: inline-block;
  cursor: ${cursorStyle};
`;

const Span = styled.span<StyleProps>`
  cursor: ${cursorStyle};

  button {
    cursor: ${cursorStyle};
  }
`;
