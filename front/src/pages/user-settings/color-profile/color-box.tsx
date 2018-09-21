import * as React from 'react';
import * as Color from 'color';
import { ChromePicker } from 'react-color';
import styled from '../../../util/styled';

/**
 * Box of color.
 */
export class ColorBox extends React.PureComponent<
  {
    /**
     * Color to show in this box.
     */
    color: string;
    /**
     * Label of box.
     */
    label: string;
    /**
     * Whether color picker is shown.
     */
    showPicker: boolean;
    /**
     * Callback for focusing.
     */
    onFocus(): void;
  },
  {}
> {
  state = {
    displayColorPicker: false,
  };
  public render() {
    const { color, label, onFocus, showPicker } = this.props;
    // determine foreground color depending on background color.
    const colorObj = new Color(color);
    const fg = colorObj.isDark() ? '#f0f0f0' : 'black';
    const styles: React.CSSProperties = {
      color: fg,
      backgroundColor: color,
    };
    return (
      <Wrapper>
        <Box style={styles} onClick={onFocus}>
          {label}
        </Box>
        {!showPicker ? null : (
          <PickerContainer>
            <ChromePicker disableAlpha color={colorObj.rgb().string()} />
          </PickerContainer>
        )}
      </Wrapper>
    );
  }
}

const Wrapper = styled.div`
  position: relative;
  top: 0;
  left: 0;
  display: inline-block;
  width: 64px;
  height: 64px;
  margin: 4px;
  vertical-align: middle;
`;

const Box = styled.button`
  display: inline-block;
  box-sizing: border-box;
  width: 64px;
  height: 64px;
  cursor: pointer;

  margin: 0;
  padding: 1ex;
  border: 1px solid #888888;
  font-size: x-small;
`;

/**
 * Floating color picker container.
 */
const PickerContainer = styled.div`
  display: inline-block;
  position: absolute;
  left: 0;
  top: 64px;
  z-index: 10;
`;
