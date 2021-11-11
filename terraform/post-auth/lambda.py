import logging

log = logging.getLogger()
log.setLevel(logging.INFO)

def handler(event, context):
    log.info(f"handler() event:")
    log.info(event)
    return event
