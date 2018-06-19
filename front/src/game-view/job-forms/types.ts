/**
 * Type of forms which need special treatment for displaying their name.
 */
export const specialNamedTypes = [
  // day's vote form.
  '_day',
  // Job form common for werewolves.
  '_Werewolf',
  // Special forms for some roles.
  'Dog1',
  'Dog2',
  'BadLady1',
  'BadLady2',
  'CraftyWolf2',
  // forms for quantum players.
  '_Quantum_Diviner',
  '_Quantum_Werewolf',
];

/**
 * Type of forms which has special content of form.
 */
export const specialContentTypes = ['GameMaster', 'Merchant', 'Witch'];

/**
 * Convert a form type into type of jobs.
 */
export function toJobType(type: string): string {
  if (type === 'Dog1' || type === 'Dog2') {
    return 'Dog';
  }
  if (type === 'BadLady1' || type === 'BadLady2') {
    return 'BadLady';
  }
  if (type === 'CraftyWolf2') {
    return 'CraftyWolf';
  }
  return type;
}
