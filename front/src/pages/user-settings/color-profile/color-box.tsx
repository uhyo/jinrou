import * as React from 'react';
import * as Color from 'color';
import styled, { withProps } from '../../../util/styled';

/**
 * Box of color.
 */
export const ColorBox: React.StatelessComponent<{
  /**
   * Color to show in this box.
   */
  color: string;
  /**
   * Label of box.
   */
  label: string;
}> = ({ color, label }) => {
  // determine foreground color depending on background color.
  const colorObj = new Color(color);
  const fg = colorObj.isDark() ? '#f0f0f0' : 'black';
  const styles: React.CSSProperties = {
    color: fg,
    backgroundColor: color,
  };
  return <Box style={styles}>{label}</Box>;
};

const Box = styled.button`
  display: inline-block;
  box-sizing: border-box;
  width: 64px;
  height: 64px;
  vertical-align: middle;
  cursor: pointer;

  margin: 4px;
  padding: 1ex;
  border: 1px solid #888888;
  font-size: x-small;
`;
