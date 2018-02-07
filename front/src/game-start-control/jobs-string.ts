/**
 * Make a string representing given jobNumbers.
 */
export function makeJobsString(jobNumbers: Map<string, number>): string {
    // TODO
    return Array.from(jobNumbers.entries(), ([key, value])=> `${key}:${value}`).join(' ');
}
