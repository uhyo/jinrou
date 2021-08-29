import styled from '../../../util/styled';
import {
  smallTextSize,
  formComponentsVerticalMergin,
} from '../../../common/style';
import { helperTextColor } from '../../../common/color';
import { phone } from '../../../common/media';

export const EditableInputs = styled.div`
  color: ${helperTextColor};
  display: grid;
  grid-template-columns: auto auto 1fr;
  gap: ${formComponentsVerticalMergin};

  ${phone`
    grid-template-columns: auto 1fr;
  `};
`;

export const InputLabel = styled.label`
  font-size: ${smallTextSize};
  line-height: 1.8;
  grid-column: 1;
`;

export const InputHelpIcon = styled.span``;

export const InputContent = styled.span`
  padding: 3px;

  ${phone`
    grid-column: 1 / 3;
  `};
`;

export const Input = styled.input`
  box-sizing: border-box;
  width: fill-available;
  width: stretch;
  padding: 2px;
  display: grid;
  &[readonly] {
    border-color: transparent;
    color: black;
    background-color: #e6e6e6;
  }
`;
